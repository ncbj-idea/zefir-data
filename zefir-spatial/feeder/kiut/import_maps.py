import logging

import geopandas as gpd
from feeder.config_schemas.kiut_config import WmsConfig
from models.map import Map
from models.prg import AdministrativeBoundary
from sqlalchemy import text
from sqlalchemy.orm.session import Session
from utils.crud import get_kiut_layer_by_name
from utils.wms import WebMapServiceBulk

logger = logging.getLogger(__name__)

_adm_geom_col = AdministrativeBoundary.geom.name
_adm_tablename = AdministrativeBoundary.__tablename__

SELECT_GRID_STM = text(
    f"""
    WITH grid AS (
        SELECT (ST_SquareGrid(:bbox_size, ST_Extent({_adm_geom_col}))).*
        FROM {_adm_tablename}
        WHERE terc = :terc
    )
    SELECT ST_AsText({_adm_geom_col}), grid.*, ST_XMin({_adm_geom_col}) as xmin,
        ST_XMax({_adm_geom_col}) as xmax, ST_YMin({_adm_geom_col}) as ymin, 
        ST_YMax({_adm_geom_col}) as ymax
    FROM grid
    """
)


def import_maps(
    db: Session,
    layer_name: str,
    import_id: int,
    terc: str,
    wms_params: WmsConfig,
):
    layer = get_kiut_layer_by_name(db, layer_name)

    df = gpd.GeoDataFrame.from_postgis(
        sql=SELECT_GRID_STM,
        con=db.get_bind(),
        params={
            "terc": terc,
            "bbox_size": wms_params.bbox_size,
        },
    )

    wmsb = WebMapServiceBulk(
        wms_params.url,
        version=wms_params.version,
        max_workers=wms_params.max_connections,
    )

    bboxes = df[["xmin", "ymin", "xmax", "ymax"]].values.tolist()
    res = wmsb.getmaps(
        bboxes=bboxes,
        layers=[layer.name],
        size=(wms_params.image_size, wms_params.image_size),
        srs=f"EPSG:{wms_params.srid}",
        format="image/png",
    )

    res = list(res)

    df["image"] = [el.get("image", None) for el in res]
    df["url"] = [el.get("url", None) for el in res]
    df["error"] = [el.get("error", None) for el in res]

    for it, row in enumerate(df.itertuples()):
        logger.debug("Inserting %d", it)
        image = row.image if not row.error else None
        g = Map(
            geom=row.geom.wkt,
            image=image,
            url=row.url,
            layer=layer.id,
            terc=terc,
            import_id=import_id,
        )
        db.add(g)
        db.flush()
    db.commit()
