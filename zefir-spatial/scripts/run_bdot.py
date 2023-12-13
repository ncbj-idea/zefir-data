import logging

from config import setup_logging
from db.base import Base
from db.session import SessionLocal
from feeder.bdot.bdot_import import import_bdot10k
from feeder.config_schemas.bdot_config import Bdot10kConfig

setup_logging()
logger = logging.getLogger(__name__)

with SessionLocal() as db:
    Base.metadata.create_all(db.bind)


urls = [
    "https://opendata.geoportal.gov.pl/bdot10k/08/0811_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/04/0410_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/22/2216_GML.zip",  # Sztum
    "https://opendata.geoportal.gov.pl/bdot10k/22/2212_GML.zip",  # Ustka
    "https://opendata.geoportal.gov.pl/bdot10k/24/2461_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/26/2601_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/14/1422_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/02/0223_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/06/0604_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/24/2405_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/18/1864_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/18/1863_GML.zip",  # Rzeszow
    "https://opendata.geoportal.gov.pl/bdot10k/30/3011_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/28/2862_GML.zip",  # Olsztyn
    "https://opendata.geoportal.gov.pl/bdot10k/14/1435_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/30/3031_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/12/1210_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/20/2063_GML.zip",  # Suwałki
    "https://opendata.geoportal.gov.pl/bdot10k/06/0617_GML.zip",
    "https://opendata.geoportal.gov.pl/bdot10k/04/0461_GML.zip",  # Bydgoszcz
    "https://opendata.geoportal.gov.pl/bdot10k/24/2417_GML.zip",  # Żywiec
]

urls = urls
for ii, url in enumerate(urls):
    config = Bdot10kConfig(
        url=url,
        tmp_tablename=f"bdot_{url[-12:-8]}",
    )
    try:
        import_bdot10k(config)
    except Exception as e:
        print("Failed", url, e)
