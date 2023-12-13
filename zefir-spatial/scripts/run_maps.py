import logging

from config import setup_logging
from db.session import SessionLocal
from feeder.config_schemas.kiut_config import KiutImportParams
from feeder.kiut.kiut_import import process_kiut_import
from feeder.kiut.modes import DefaultModes

setup_logging()
logger = logging.getLogger(__name__)
db = SessionLocal()

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
    ("2212011", "Ustka"),
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

tercs = tercs_1 + tercs_2 + terc_broken


def _run(tercs):
    for params, region_name in tercs:
        try:
            for layer in params.layers:
                layer_name = layer.value
                logger.info(
                    "(%s) Import: maps table (layer '%s')", params.terc, layer_name
                )
                process_kiut_import(
                    db, terc=params.terc, layer_name=layer_name, config=params.config
                )

            logger.info("(%s) Finished.", params.terc)
        except ValueError as e:
            print("ERROR ", params.terc, e)


if __name__ == "__main__":
    _run(tercs)
