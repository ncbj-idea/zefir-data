import logging

from db.base_class import Base
from db.session import SessionLocal
from feeder.config_schemas.kiut_config import KiutConfig
from feeder.kiut.import_maps import import_maps
from feeder.kiut.map_analyze.factory import get_grid_checker
from feeder.kiut.polygonize import ArraySlicer, import_tiles
from models.map import Map
from utils.constants import CONFIG_KEY
from utils.crud import create_import_to_terc_mapping, create_metadata_for_import

logger = logging.getLogger(__name__)


def process_kiut_import(db, terc: str, layer_name: str, config: KiutConfig):
    logger.info("(%s) Import: maps table (layer '%s')", terc, layer_name)
    metadata = {"terc": terc, "layer_name": layer_name, CONFIG_KEY: config.dict()}
    meta_obj = create_metadata_for_import(db, Map.__tablename__, metadata=metadata)
    create_import_to_terc_mapping(db, import_id=meta_obj.id, terc=terc)
    import_maps(
        db,
        layer_name,
        terc=terc,
        import_id=meta_obj.id,
        wms_params=config.wms,
    )
    logger.info("(%s) Import: tiles table. (layer '%s')", terc, layer_name)
    polygonizer = get_grid_checker(layer_name, config.polygonization)
    slicer = ArraySlicer(config.number_of_slices_of_image_side)
    import_tiles(db, meta_obj.id, polygonizer, slicer, config.wms.srid)
    logger.info("(%s)(%s) Finished.", meta_obj.id, terc)
    #


if __name__ == "__main__":
    with SessionLocal() as db:
        Base.metadata.create_all(db.bind)

        process_kiut_import(
            db,
            terc="0604011",
            layer_name="przewod_cieplowniczy",
            config=KiutConfig(),
        )
