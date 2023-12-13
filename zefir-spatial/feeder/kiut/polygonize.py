import io
import logging
from itertools import product
from typing import Any, Dict, List, Tuple

import numpy as np
from feeder.kiut.geomap_array import GeomapRgbaArray
from feeder.kiut.layers import LayerNames
from feeder.kiut.map_analyze.layer_checkers.interface import LayerChecker
from geoalchemy2.shape import from_shape
from models.map import Map
from models.tile import Tile
from PIL import Image
from sqlalchemy.engine.row import RowMapping
from sqlalchemy.orm.session import Session
from utils.crud import get_kiut_layername_to_id_dict
from utils.image.color import is_background
from utils.image.serialize import image_to_bytes
from utils.typings import LayernameToId_DictT

logger = logging.getLogger(__name__)


ExistingLayers = List[LayerNames]


class ArraySlicer:
    def __init__(self, number_of_slices_of_image_side=100):
        self.number_of_slices_of_image_side = number_of_slices_of_image_side

    def to_tiles(
        self,
        obj: GeomapRgbaArray,
    ) -> List[Tuple[GeomapRgbaArray, Dict[str, Any]]]:
        x_idx = np.linspace(
            0, obj.array.shape[1], self.number_of_slices_of_image_side + 1, dtype="int"
        )
        y_idx = np.linspace(
            0, obj.array.shape[0], self.number_of_slices_of_image_side + 1, dtype="int"
        )
        x_slices = zip(x_idx[:-1], x_idx[1:])
        y_slices = zip(y_idx[:-1], y_idx[1:])
        slices = list(product(y_slices, x_slices))
        list_of_objs = []
        for row_slice, col_slice in slices:
            geoarr = GeomapRgbaArray(
                array=obj.array[slice(*row_slice), slice(*col_slice)],
                minx=obj.x(col_idx=col_slice[0]),
                miny=obj.y(row_idx=row_slice[0]),
                maxx=obj.x(col_idx=col_slice[1]),
                maxy=obj.y(row_idx=row_slice[1]),
            )
            debug_data = {"row_slice": str(row_slice), "col_slice": str(col_slice)}
            el = (geoarr, debug_data)
            list_of_objs.append(el)
        return list_of_objs


def _is_blank(arr: np.ndarray) -> bool:  # type: ignore
    return is_background(arr).all()


MapDataQueryResult_Type = RowMapping
Mapping_Type = List[Dict[str, Any]]


def _process_map(
    map_data: MapDataQueryResult_Type,
    checker: LayerChecker,
    slicer: ArraySlicer,
    layername2id: LayernameToId_DictT,
    srid: int,
) -> Mapping_Type:
    map_id = map_data["id"]
    # logger.debug("Process map %d", map_id)
    image = Image.open(io.BytesIO(map_data["image"]))
    image = image.convert("RGBA")
    list_of_mappings = []  # type: ignore
    arr = np.array(image)
    # If the whole map is blank, then all tiles are also blank
    if _is_blank(arr):
        logger.debug("Process map %d is empty. Skiped.", map_id)
        return list_of_mappings
    geoarray = GeomapRgbaArray(
        arr,
        minx=map_data["xmin"],
        maxx=map_data["xmax"],
        miny=map_data["ymin"],
        maxy=map_data["ymax"],
    )

    tiles_data = slicer.to_tiles(geoarray)
    logger.debug("Map %d is splitted to %d tiles", map_id, len(tiles_data))

    for tile, debug_data in tiles_data:
        existing_layers = checker.get_existing_layers(tile.array)

        for layer in existing_layers:
            mapping = {
                "map_id": map_id,
                "geom": from_shape(tile.get_geom(), srid=srid),
                "layer": layername2id[layer],
                "debug": debug_data,  # (map_id == 2604) & (debug_data["col_slice"] == "(820, 830)") & (debug_data["row_slice"]: "(980, 990)")
                "image": image_to_bytes(tile.get_image()),
            }
            list_of_mappings.append(mapping)
    logger.debug("Process map %d finished", map_id)
    return list_of_mappings


def import_tiles(
    db: Session, import_id: int, checker: LayerChecker, slicer: ArraySlicer, srid: int
):
    stm = f"""
        SELECT map.*, 
               ST_XMin(geom) as xmin,
               ST_XMax(geom) as xmax,
               ST_YMin(geom) as ymin, 
               ST_YMax(geom) as ymax 
        FROM {Map.__tablename__} as map 
        WHERE import_id = '{import_id}'
    """
    maps = db.execute(stm).mappings().all()
    layername2id = get_kiut_layername_to_id_dict(db)
    error_count, maps_number = 0, len(maps)
    logger.info("Fetched %d maps from table maps", maps_number)
    for map_data in maps:
        try:
            list_of_mappings = _process_map(
                map_data, checker, slicer, layername2id, srid
            )
            if list_of_mappings:
                db.bulk_insert_mappings(mapper=Tile, mappings=list_of_mappings)
        except Exception:
            map_id = map_data["id"]
            logger.exception("Error when process map %d.", map_id)
            error_count += 1
            continue
    logger.info(
        "Processed with success %d maps. With errors %d.", maps_number, error_count
    )

    db.commit()


# if __name__ == "__main__":
# from db.session import SessionLocal
#   with SessionLocal() as db:
#         pass
