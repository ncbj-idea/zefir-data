from config import setup_logging
from feeder.config_schemas.prg_config import AddressPointsConfig
from feeder.prg.address_points_import import import_address_points

setup_logging()


def _prepare_url(teryt_code: str):
    return (
        f"https://opendata.geoportal.gov.pl/prg/adresy/{teryt_code}_Punkty_Adresowe.zip"
    )


teryts = [
    "04",
    "06",
    "08",
    "12",
    "14",
    "18",
    "20",
    "22",
    "24",
    "28",
    "30",
]

failed = 0
for teryt in teryts:
    url = _prepare_url(teryt)
    config = AddressPointsConfig(url=url, tmp_tablename=f"tmp_address_pounts_{teryt}")
    try:
        import_address_points(config)
    except Exception as e:
        failed += 1
        print("Failed", url, e)
print("Failed ", failed, "out of ", len(teryts))
