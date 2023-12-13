import logging
from pathlib import Path
from tempfile import TemporaryDirectory

from owslib.wfs import WebFeatureService
from sqlalchemy import Table, select, text
from sqlalchemy.orm.session import Session

from config import settings
from db.base import Base
from db.session import SessionLocal
from feeder.config_schemas.prg_config import AdmBoundariesConfig
from models.prg import AdministrativeBoundary
from utils.constants import CONFIG_KEY
from utils.crud import create_metadata_for_import
from utils.gdal import Ogr2OgrCaller

logger = logging.getLogger(__name__)

default = AdmBoundariesConfig()


def _import_raw_gminy_boundaries(
    url: str,
    tablename: str,
    table_schema: str,
    tmpdir: str,
    layer_name: str,
    wfs_version: str,
    timeout: int,
):
    # not working with default version (2.0.0), thus version 1.1 is hardcoded
    logger.debug("WFS_version %s", wfs_version)
    wfs = WebFeatureService(url, version=wfs_version, timeout=timeout)
    if not layer_name in wfs.contents:
        raise KeyError(
            "No  %s (expected) layer in returned layers from WFS service",
            layer_name,
        )
    response = wfs.getfeature(typename=layer_name)

    with TemporaryDirectory(dir=tmpdir) as tmpdirname:
        tmpdirname = Path(tmpdirname)
        gml_path = tmpdirname / f"prg_adm_boundaries.gml"
        with open(gml_path, "wb") as egib_gml:
            egib_gml.write(response.read())
        full_tablename = f"{table_schema}.{tablename}"
        ogr2ogr = Ogr2OgrCaller(tablename=full_tablename, layer_name=layer_name)
        ogr2ogr(str(gml_path))


def _process_boundaries_normalization(db: Session, raw_table: Table, import_id: int):
    # fmt: off
    stm = select(
        text(
            ":import_id, left(jpt_kod_je, 6) || right(jpt_kod_je, 1) terc,"
            " lower(jpt_nazwa_) as name, \"msgeometry\" as geom" # noqa
        )
    ).select_from(raw_table)
    # fmt: on
    columns = [
        AdministrativeBoundary.import_id.name,
        AdministrativeBoundary.terc.name,
        AdministrativeBoundary.name.name,
        AdministrativeBoundary.geom.name,
    ]
    ins = AdministrativeBoundary.__table__.insert().from_select(columns, stm)
    db.execute(ins, {"import_id": import_id})
    db.flush()


def import_gminy_boundaries(
    config: AdmBoundariesConfig = AdmBoundariesConfig(),
    remove_staging_table: bool = False,
):
    with SessionLocal() as db:
        try:
            logger.info("Process administrative boundaries.")
            meta_obj = create_metadata_for_import(
                db,
                tablename=AdministrativeBoundary.__tablename__,
                metadata={CONFIG_KEY: config.dict()},
            )

            _import_raw_gminy_boundaries(
                url=config.url,
                tablename=config.tmp_tablename,
                table_schema=config.tmp_table_schema,
                tmpdir=settings.TMP_DIR,
                layer_name=config.layer_name,
                wfs_version=config.wfs_version,
                timeout=config.timeout,
            )

            raw_table = Table(
                config.tmp_tablename,
                Base.metadata,
                autoload_with=db.bind,
                schema=config.tmp_table_schema,
            )
            _process_boundaries_normalization(db, raw_table, meta_obj.id)
            if remove_staging_table:
                raw_table.drop(db.bind)
            db.commit()
            logger.info("Administrative boundaries inserted to db")

        except Exception as e:
            logger.error("Failed %s. Changes are rolled back", config.url)
            db.rollback()
            raise e


if __name__ == "__main__":
    with SessionLocal() as db:
        Base.metadata.create_all(db.bind)
    import_gminy_boundaries()
