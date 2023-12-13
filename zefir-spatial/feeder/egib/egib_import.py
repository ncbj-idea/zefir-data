import logging
import xml.etree.ElementTree as ET
from pathlib import Path
from tempfile import NamedTemporaryFile
from typing import Counter

import urllib3
from config import settings
from db.base import Base
from db.session import SessionLocal
from feeder.config_schemas.egib_config import EgibConfig
from feeder.egib.egib_procedures import (
    CREATE_EGIB_UPDATE_PROC,
    EGIB_UPDATE_PROCEDURE_NAME,
)
from models.egib import Egib
from owslib.crs import Crs
from owslib.feature.wfs200 import WebFeatureService_2_0_0
from owslib.util import Authentication
from owslib.wfs import WebFeatureService
from sqlalchemy import Table, bindparam, column, func
from sqlalchemy.orm.session import Session
from utils.constants import CONFIG_KEY
from utils.crud import create_metadata_for_import
from utils.gdal import Ogr2OgrCaller
from utils.sql import build_insert, bulild_json_column, call_procedure, create_procedure
from utils.wfs import get_wfs_version

logger = logging.getLogger(__name__)


def _validate_if_crs_is_correct(gml: bytes, expected_crs: Crs):
    gml_root = ET.fromstring(gml)

    crs_counter: Counter = Counter()
    for el in gml_root.iter():
        if "srsName" in el.attrib:
            crs_counter.update([el.attrib["srsName"]])
    if len(crs_counter) == 0:
        raise ValueError(
            "No CRS data found in GML file. File may be empty, or elements in the XML"
            " file doesnt contain attribute named 'srsName'"
        )
    if len(crs_counter) > 1:
        raise ValueError(f"More than one CRS found in GML file: {crs_counter}")

    found_crs_name = next(iter(crs_counter.keys()))
    found_crs = Crs(found_crs_name)
    if found_crs != expected_crs:
        logger.warning(
            "CRS doesnt match. Expected: %s. Found in file: %s",
            expected_crs.getcodeurn(),
            found_crs_name,
        )


def _import_raw_egib_from_url_to_staging_area(
    url: str,
    tablename: str,
    tmpdir,
    layer_name: str,
    fixed_axis_order: bool,
    replace: bool,
):
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    wfs_version = get_wfs_version(url)
    wfs = WebFeatureService(
        url, version=wfs_version, auth=Authentication(verify=False), timeout=300
    )
    typenames = [typename for typename in wfs.contents if layer_name in typename]
    if len(typenames) != 1:
        raise ValueError("FIXME!")
    budynki_layer_name = typenames[0]
    default_crs: Crs = wfs.contents[typenames[0]].crsOptions[0]
    if isinstance(wfs, WebFeatureService_2_0_0):
        # Cannot set srsname for method `getfeature` in `WebFeatureService_2_0_0`
        response = wfs.getfeature(typename=budynki_layer_name)
    else:
        response = wfs.getfeature(typename=budynki_layer_name, srsname=default_crs)
    content = response.read()
    _validate_if_crs_is_correct(content, default_crs)
    with NamedTemporaryFile(dir=tmpdir, mode="w+b") as tmpfile:
        tmpfile.write(content)
        path = str(Path(tmpdir) / Path(tmpfile.name).name)
        # tmpfile.name return an absolute path, we need a relative to use docker containers # noqa
        Ogr2OgrCaller(
            tablename=tablename,
            replace=replace,
            layer_name=layer_name,
            fixed_axis_order=fixed_axis_order,
        )(
            path  # , default_crs.getcodeurn()
        )


def _append_egib_table(
    db: Session, import_id: int, raw_table: Table, geometry_column_name: str
):
    jsonized_cols = [
        column(col.name)
        for col in raw_table.columns
        if col.name != geometry_column_name
    ]

    geom = column(geometry_column_name)
    raw_geom = func.ST_AsEWKT(geom).label(Egib.geom.name)
    jsonized_cols.append(raw_geom)

    geom = func.ST_Transform(geom, Egib.geom.type.srid)
    geom = func.ST_CurveToLine(geom)

    placeholder = "import_id"
    columns = [
        bindparam(placeholder).label(Egib.import_id.name),
        geom.label(Egib.geom.name),
        bulild_json_column(jsonized_cols).label(Egib.other.name),
    ]
    ins = build_insert(columns, raw_table, Egib.__table__)
    logger.debug("Stm: %s", ins)
    db.execute(ins, {placeholder: import_id})


def _import_data_to_db(config: EgibConfig, remove_staging_table: bool) -> int:
    # insert data to db
    with SessionLocal() as db:
        try:
            meta_obj = create_metadata_for_import(
                db,
                tablename="egib",
                metadata={CONFIG_KEY: config.dict()},
            )
            full_tablename = f"{config.tmp_table_schema}.{config.tmp_tablename}"

            _import_raw_egib_from_url_to_staging_area(
                url=config.url,
                tablename=full_tablename,
                tmpdir=settings.TMP_DIR,
                layer_name=config.layer_name,
                fixed_axis_order=config.fixed_axis_order,
                replace=True,
            )

            raw_table = Table(
                config.tmp_tablename,
                Base.metadata,
                autoload_with=db.bind,
                schema=config.tmp_table_schema,
            )

            _append_egib_table(
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


def import_egib(config: EgibConfig, remove_staging_table: bool = False):
    logger.info(
        "Start processing egib from url '%s' using layer '%s'",
        config.url,
        config.layer_name,
    )
    import_id = _import_data_to_db(config, remove_staging_table)
    logger.info("(%s) Completed importing to db", import_id)
    try:
        create_procedure(CREATE_EGIB_UPDATE_PROC)
        call_procedure(EGIB_UPDATE_PROCEDURE_NAME, import_id)
        logger.info("(%s) Completed data normalization", import_id)
    except Exception:
        logger.error(
            f"(%s) Failed to normalize '%s'. Try to manually execute procedure"
            f" 'CALL %s('%s');' on db to fix it.",
            import_id,
            Egib.__tablename__,
            EGIB_UPDATE_PROCEDURE_NAME,
            import_id,
        )
    logger.info("(%s) Completed processing egib for url '%s'.", import_id, config.url)
