import logging
from io import BytesIO
from tempfile import TemporaryDirectory
from typing import IO
from zipfile import ZipFile

from config import settings
from db.base import Base
from db.session import SessionLocal
from feeder.config_schemas.prg_config import AddressPointsConfig
from feeder.prg.addr_points_procedures import (
    ADDR_POINTS_UPDATE_PROCEDURE_NAME,
    CREATE_ADDR_POINTS_UPDATE_PROC,
)
from models.address_point import AddressPoint
from sqlalchemy import Table, bindparam, column, select, text
from sqlalchemy.orm.session import Session
from utils.constants import CONFIG_KEY
from utils.crud import create_metadata_for_import
from utils.gdal import Ogr2OgrCaller
from utils.remote import get_content_from_remote
from utils.sql import build_insert, bulild_json_column, call_procedure, create_procedure

logger = logging.getLogger(__name__)


def _import_data_from_zip(source: IO[bytes], ogr2ogr: Ogr2OgrCaller, tmpdir: str):
    with ZipFile(source) as zip:
        files = zip.namelist()
        if len(files) != 1:
            raise ValueError(f"Unexpected number of files. Expected 1. Given: {files}")
        for file in files:
            with TemporaryDirectory(dir=tmpdir) as tmpdirname:
                filepath = zip.extract(file, tmpdirname)
                logger.debug("Data extracted to %s.", filepath)
                ogr2ogr(source=filepath)


def _import_raw_to_staging_schema(
    url, tmpdir, table_name, table_schema, layer_name, replace
):
    full_tablename = f"{table_schema}.{table_name}"
    ogr2ogr = Ogr2OgrCaller(full_tablename, layer_name, replace, layer_type="POINT")
    stream = BytesIO(get_content_from_remote(url))
    _import_data_from_zip(stream, ogr2ogr, tmpdir)


def _append_address_table(
    db: Session, import_id: int, raw_table: Table, geometry_column_name: str
):
    jsonized_cols = [
        column(col.name) for col in raw_table.columns if col.name != geometry_column_name
    ]
    geom = column(geometry_column_name)
    # geom = func.ST_Transform(geom, Egib.geom.type.srid)
    # geom = func.ST_CurveToLine(geom)

    placeholder = "import_id"
    columns = [
        bindparam(placeholder).label(AddressPoint.import_id.name),
        geom.label(AddressPoint.geom.name),
        bulild_json_column(jsonized_cols).label(AddressPoint.other.name),
    ]
    ins = build_insert(columns, raw_table, AddressPoint.__table__)
    logger.debug("Stm: %s", ins)
    db.execute(ins, {placeholder: import_id})


def _import_data_to_db(
    config: AddressPointsConfig,
    remove_staging_table: bool,
):
    with SessionLocal() as db:
        try:
            meta_obj = create_metadata_for_import(
                db,
                tablename=AddressPoint.__tablename__,
                metadata={CONFIG_KEY: config.dict()},
            )
            _import_raw_to_staging_schema(
                url=config.url,
                table_name=config.tmp_tablename,
                table_schema=config.tmp_table_schema,
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
            _append_address_table(
                db, meta_obj.id, raw_table, config.geometry_column_name
            )
            if remove_staging_table:
                raw_table.drop(db.bind)
            db.commit()
            return meta_obj.id

        except Exception as e:
            logger.error("Failed %s. Changes are rolled back", config.url)
            db.rollback()
            raise e


def import_address_points(
    config: AddressPointsConfig, remove_staging_table: bool = False
):
    logger.info(
        "Start processing address points from url '%s' using layer '%s'",
        config.url,
        config.layer_name,
    )
    import_id = _import_data_to_db(config, remove_staging_table)
    logger.info("(%s) Completed importing to db", import_id)
    try:
        create_procedure(CREATE_ADDR_POINTS_UPDATE_PROC)
        call_procedure(ADDR_POINTS_UPDATE_PROCEDURE_NAME, import_id)
        logger.info("(%s) Completed data normalization", import_id)
    except Exception:
        logger.error(
            f"(%s) Failed to normalize '%s'. Try to manually execute procedure"
            f" 'CALL %s('%s');' on db to fix it.",
            import_id,
            AddressPoint.__tablename__,
            ADDR_POINTS_UPDATE_PROCEDURE_NAME,
            import_id,
        )
    logger.info(
        "(%s) Completed processing address points for url '%s'.", import_id, config.url
    )


if __name__ == "__main__":
    with SessionLocal() as db:
        Base.metadata.create_all(db.bind)
        url = "https://opendata.geoportal.gov.pl/prg/adresy/08_Punkty_Adresowe.zip"
        config = AddressPointsConfig(url=url)

        import_address_points(config)

        # raw_table = Table(
        #     config.tmp_tablename,
        #     Base.metadata,
        #     autoload_with=db.bind,
        #     schema=config.tmp_table_schema,
        # )
        # _append_address_table(db, 31, raw_table, "pozycja")
        # db.commit()
