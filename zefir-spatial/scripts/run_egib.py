import datetime
import logging

from config import setup_logging
from db.session import SessionLocal
from feeder.config_schemas.egib_config import EgibConfig
from feeder.egib.egib_import import import_egib

setup_logging()

logger = logging.getLogger(__name__)

urls = [
    ("https://zary.geoportal2.pl/map/geoportal/wfs.php", "geometria"),
    ("https://mapy.geoportal.gov.pl/wss/ext/PowiatoweBazyEwidencjiGruntow/2216", "msgeometry"),  # Sztum
    ("https://tarnobrzeg.geoportal2.pl/map/geoportal/wfs.php", "geometria"),
    ("http://osrodek.erzeszow.pl/map/geoportal/wfs.php", "geometria"),  # error ssl
    ("https://services.gugik.gov.pl/cgi-bin/2862", "msgeometry"),  # Olsztyn
    ("https://powiat-wyszkowski.geoportal2.pl/map/geoportal/wfs.php", "geometria"),
    ("https://geoportal.um.suwalki.pl/ggp?service=WFS&request=GetCapabilities", "wkb_geometry"),  # Suwałki
    ("https://powiatswidnik.geoportal2.pl/map/geoportal/wfs.php", "geometria"),
    ("https://services.gugik.gov.pl/cgi-bin/0461", "msgeometry"), # Not Found
    ("https://wms.powiat.slupsk.pl/iip/ows", "msgeometry")  # Ustka
]

configs = []
for ii, (url, geometry_column) in enumerate(urls):
    configs.append(
        EgibConfig(
            url=url,
            tmp_tablename=f"egib_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S%f')}",
            geometry_column_name=geometry_column,
        )
    )

configs += [
    EgibConfig(
        url="https://wms.powiatkoscian.pl/koscian-egib",
        tmp_tablename=f"egib_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S%f')}",
        geometry_column_name="msgeometry",
        fixed_axis_order=True,
    ),
    EgibConfig(
        url="https://ikerg.bielsko-biala.pl/bielsko-egib",  # error ssl
        tmp_tablename=f"egib_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S%f')}",
        geometry_column_name="msgeometry",
        fixed_axis_order=True,
    ),
]


db = SessionLocal()
failed = 0
for config in configs:
    try:
        import_egib(config)
    except Exception as e:
        print("Failed", config.url, e)
