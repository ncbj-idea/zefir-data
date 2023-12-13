from pathlib import Path

from pydantic import BaseSettings, HttpUrl

from config import settings


class Bdot10kConfig(BaseSettings):
    url: HttpUrl
    layer_name: str = "OT_BUBD_A"
    tmp_tablename: str = "tmp_bdot"
    tmp_table_schema: str = settings.DB_STAGING_SCHEMA
    geometry_column_name: str = "wkb_geometry"
