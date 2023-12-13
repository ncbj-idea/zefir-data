import datetime
import logging
from pathlib import Path

import pandas as pd
from config import setup_logging
from db.base import Base
from db.session import SessionLocal
from feeder.bdot.bdot_import import import_raw_bdot_data
from feeder.kiut.kiut_import import process_kiut_import
from feeder.kiut.modes import DefaultModes
from feeder.config_schemas.kiut_config import KiutImportParams

setup_logging()
logger = logging.getLogger(__name__)
db = SessionLocal()
Base.metadata.create_all(db.bind)


def select_and_save(terc: str, name: str):
    stm = f"""
    with _bdot_raw AS (SELECT * FROM tmp.bdot_{terc[0:4]}_gml),
        _terc AS (SELECT '{terc[0:6]}_{terc[6]}'),
    adm_bound AS  (
        SELECT adm.msgeometry as geom FROM administrative_boundaries adm
        WHERE adm.jpt_kod_je = (SELECT * FROM _terc)
    ),
    bdot as (
        SELECT bdot.*, st_area(geometria) as powierzchnia_obrysu_m2 from _bdot_raw as bdot
        WHERE ST_Intersects(bdot.geometria, (SELECT adm_bound.geom FROM adm_bound))
    ),
    gas_tiles AS (
        SELECT tile.* FROM tile
        LEFT JOIN map m on m.id = tile.map_id
        WHERE tile.layer = 4
    ),
    heat_tiles AS  (
        SELECT tile.* FROM tile
        LEFT JOIN map m on m.id = tile.map_id
        WHERE tile.layer = 3
    ),
    join_grids AS  (
        SELECT bdot.*,
            gas_dist,
            heat_dist,
            CASE WHEN heat_dist<=10 THEN True ELSE False END as heat_connected,
            CASE WHEN gas_dist<=10 THEN True ELSE False END as gas_connected
        FROM bdot
        LEFT JOIN LATERAL (
            SELECT gas.*,
                    St_Distance(gas.geom, bdot.geometria) AS gas_dist
            FROM gas_tiles gas
            ORDER BY bdot.geometria <-> gas.geom
            LIMIT 1
            ) AS gas_join ON true
        LEFT JOIN LATERAL (
            SELECT heat.*,
                    St_Distance(heat.geom, bdot.geometria) AS heat_dist
            FROM heat_tiles heat
            ORDER BY bdot.geometria <-> heat.geom
            LIMIT 1
            ) AS heat_join ON true
        )
    SELECT * FROM  join_grids;
    """
    df = pd.read_sql(stm, db.get_bind())
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M")
    filename = f'{terc}_{timestamp}_{name.replace(" ", "_")}'
    with pd.ExcelWriter(f"./tmp/{filename}.xlsx") as writer:
        df.to_excel(writer, sheet_name="dane")
        agg = df.groupby(["heat_connected", "gas_connected"])["ogc_fid"].count()
        agg.to_excel(writer, sheet_name="dostep_do_sieci")


DEFAULT_LAYERS = ("przewod_cieplowniczy", "przewod_gazowy")

tercs_1 = [
    ("2216054", "Sztum miasto"),
    ("2601014", "Busko Zdroj miasto"),
    ("1422024", "Chorzale"),
    ("0604011", "Chrubieszow"),
    ("1864011", "Tarnobrzeg"),
    ("1863011", "Rzeszow"),
    ("2862011", "Olsztyn"),
    ("1435054", "Wyszkow"),
    ("3031011", "Zlotow"),
    ("2063011", "Suwalki"),
    ("0617011", "Swidnik"),
]

tercs_1 = [
    (
        KiutImportParams(
            terc=terc,
            config=DefaultModes.SHOULD_BE_OPTIMAL,
            layers=DEFAULT_LAYERS,
        ),
        cityname,
    )
    for terc, cityname in tercs_1
]

tercs_2 = [
    (
        KiutImportParams(
            terc="2212011",
            config=DefaultModes.SHOULD_WORK_FOR_PROBLEMATIC_MZK_CITIES,
            layers=("przewod_niezidentyfikowany",),
        ),
        "Ustka",
    ),  # done
    (
        KiutImportParams(
            terc="2405011",
            config=DefaultModes.SHOULD_WORK_FOR_PROBLEMATIC_MZK_CITIES,
            layers=("przewod_niezidentyfikowany",),
        ),
        "Knurów",
    ),  # done
    (
        KiutImportParams(
            terc="3011024",
            config=DefaultModes.SHOULD_WORK_FOR_PROBLEMATIC_MZK_CITIES,
            layers=("przewod_niezidentyfikowany",),
        ),
        "Czempiń",
    ),  # done
]

terc_broken = [
    (
        KiutImportParams(
            terc="0410024",
            config=DefaultModes.SHOULD_WORK_FOR_PROBLEMATIC_MZK_CITIES,
            layers=("przewod_niezidentyfikowany",),
        ),
        "Mrocza",
    ),  # beznadziejny serwer, wywala tyimeouty!
    (
        KiutImportParams(
            terc="2461011",
            config=DefaultModes.SHOULD_WORK_FOR_PROBLEMATIC_MZK_CITIES,
            layers=("przewod_niezidentyfikowany",),
        ),
        "Bielsko-Biała",
    ),  # 5000 map !!! za duzo na komputer lokalny :(
]

# tercs = tercs_1
# tercs = tercs_2
# tercs = terc_broken
tercs = tercs_1 + tercs_2 + terc_broken

for params, region_name in tercs:
    try:
        print("START ", params.terc)
        url = f"https://opendata.geoportal.gov.pl/bdot10k/{params.terc[0:2]}/{params.terc[0:4]}_GML.zip"
        print(url)
        import_raw_bdot_data(url, "tmp.bdot_" + str(Path(url).stem))
        print("OK", url)

        print("maps")
        for layer in params.layers:
            layer_name = layer.value
            logger.info("(%s) Import: maps table (layer '%s')", params.terc, layer_name)
            process_kiut_import(
                db, terc=params.terc, layer_name=layer_name, config=params.config
            )

        logger.info("(%s) Finished.", params.terc)

        print("generating excel")
        select_and_save(params.terc, region_name)
    except ValueError as e:
        print("ERROR ", params.terc, e)
