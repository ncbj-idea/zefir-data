from pathlib import Path

from config import settings
from pydantic import BaseSettings, HttpUrl


class EgibConfig(BaseSettings):
    url: HttpUrl
    layer_name: str = "budynki"
    tmp_tablename: str = "tmp_egib"
    tmp_table_schema: str = settings.DB_STAGING_SCHEMA
    geometry_column_name: str = "geometria"
    fixed_axis_order: bool = False
