from config import settings
from pydantic import BaseSettings, HttpUrl


class AdmBoundariesConfig(BaseSettings):
    url: HttpUrl = "http://mapy.geoportal.gov.pl/wss/service/PZGIK/PRG/WFS/AdministrativeBoundaries"
    layer_name: str = "A05_Granice_jednostek_ewidencyjnych"
    tmp_tablename: str = "tmp_administrative_boundaries"
    wfs_version: str = "1.1.0"
    timeout: int = 600
    tmp_table_schema: str = settings.DB_STAGING_SCHEMA


class AddressPointsConfig(BaseSettings):
    url: HttpUrl
    layer_name: str = "PRG_PunktAdresowy"
    tmp_tablename: str = "tmp_address_points"
    tmp_table_schema: str = settings.DB_STAGING_SCHEMA
    geometry_column_name: str = "wkb_geometry"
