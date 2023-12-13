import logging
from io import BytesIO
from tempfile import TemporaryDirectory
from zipfile import ZipFile

from config import settings
from db.base import Base
from db.session import SessionLocal
from feeder.bdot.bdot_procedures import (
    BDOT_UPDATE_PROCEDURE_NAME,
    CREATE_BDOT_UPDATE_PROC,
)
from feeder.config_schemas.bdot_config import Bdot10kConfig
from models.bdot import Bdot10k
from sqlalchemy import Table, bindparam, column, func
from sqlalchemy.orm.session import Session
from utils.constants import CONFIG_KEY
from utils.crud import create_metadata_for_import
from utils.gdal import Ogr2OgrCaller
from utils.remote import get_content_from_remote
from utils.sql import build_insert, bulild_json_column, call_procedure, create_procedure

logger = logging.getLogger(__name__)


def _unzip_layer(zip_path, outdir, layer_name):
    with ZipFile(zip_path) as zip:
        building_xmls = [
            memb
            for memb in zip.infolist()
            if not zip.infolist()[0].is_dir() and layer_name in memb.filename
        ]
        if len(building_xmls) == 1:
            building_xml = building_xmls[0]
        else:
            raise ValueError("FIXME")
        filepath = zip.extract(building_xml.filename, path=outdir)
    return filepath


def _import_raw_bdot_data(url, tablename, replace, tmpdir, layer_name):
    with TemporaryDirectory(dir=tmpdir) as tmpdirname:

        stream = BytesIO(get_content_from_remote(url))
        filepath = _unzip_layer(stream, tmpdirname, layer_name)
        Ogr2OgrCaller(tablename=tablename, replace=replace, layer_name=layer_name)(
            filepath
        )


def _append_bdot10k_table(
    db: Session, import_id: int, raw_table: Table, geometry_column_name: str
):

    jsonized_cols = [
        column(col.name) for col in raw_table.columns if col.name != geometry_column_name
    ]
    geom = column(geometry_column_name)
    raw_geom = func.ST_AsEWKT(geom).label(Bdot10k.geom.name)
    jsonized_cols.append(raw_geom)

    placeholder = "import_id"
    columns = [
        bindparam(placeholder).label(Bdot10k.import_id.name),
        geom.label(Bdot10k.geom.name),
        bulild_json_column(jsonized_cols).label(Bdot10k.other.name),
    ]
    ins = build_insert(columns, raw_table, Bdot10k.__table__)
    logger.debug("Stm: %s", ins)
    db.execute(ins, {placeholder: import_id})


def _import_data_to_db(config: Bdot10kConfig, remove_staging_table: bool) -> int:
    # insert data to db
    with SessionLocal() as db:
        try:
            meta_obj = create_metadata_for_import(
                db,
                tablename="bdot",
                metadata={CONFIG_KEY: config.dict()},
            )
            full_tablename = f"{config.tmp_table_schema}.{config.tmp_tablename}"
            _import_raw_bdot_data(
                url=config.url,
                tablename=full_tablename,
                tmpdir=settings.TMP_DIR,
                layer_name=config.layer_name,
                replace=True,
            )

            raw_table = Table(
                config.tmp_tablename,
                Base.metadata,
                autoload_with=db.bind,
                schema=config.tmp_table_schema,
            )
            _append_bdot10k_table(
                db,
                meta_obj.id,
                raw_table,
                geometry_column_name=config.geometry_column_name,
            )
            if remove_staging_table:
                raw_table.drop(db.bind)
            db.commit()
            return meta_obj.id
        except Exception as e:
            logger.error("Failed '%s'. Changes are rolled back", config.url)
            db.rollback()
            raise e


def import_bdot10k(config: Bdot10kConfig, remove_staging_table: bool = False):
    logger.info(
        "Start processing bdot10k from url '%s' using layer '%s'",
        config.url,
        config.layer_name,
    )
    import_id = _import_data_to_db(config, remove_staging_table)
    logger.info("(%s) Completed import to db", import_id)
    try:
        create_procedure(CREATE_BDOT_UPDATE_PROC)
        call_procedure(BDOT_UPDATE_PROCEDURE_NAME, import_id)
        logger.info("(%s) Completed data normalization", import_id)
    except Exception:
        logger.error(
            f"(%s) Failed to normalize '%s'. Try to manually execute procedure"
            f" 'CALL %s('%s')' on database to fix it.",
            import_id,
            Bdot10k.__tablename__,
            BDOT_UPDATE_PROCEDURE_NAME,
            import_id,
        )
    logger.info(
        "(%s) Completed processing bdot10k for url '%s'.", import_id, config.url
    )
