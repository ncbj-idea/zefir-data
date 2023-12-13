import logging
import logging.config
from pathlib import Path
from typing import Optional

import yaml
from pydantic import BaseSettings, DirectoryPath, FilePath

ROOT_DIR = Path(__file__).parent


class Settings(BaseSettings):
    LOGGING_CONFIG_PATH: Optional[FilePath] = ROOT_DIR / "logging_cfg.yml"

    POSTGRES_HOST_ADDRESS: str = "0.0.0.0"
    POSTGRES_DB: str
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_HOST_PORT: int = 5432
    POSTGRES_CONTAINER_PORT: int = 5432

    DB_SRID: int = 2180
    DB_STAGING_SCHEMA: str = "tmp"

    TMP_DIR: DirectoryPath = Path.cwd()  # directory to store tmp files

    class Config:
        case_sensitive = True


settings = Settings()


def setup_logging():
    try:
        with open(settings.LOGGING_CONFIG_PATH, "r") as f:
            config = yaml.safe_load(f)
            logging.config.dictConfig(config)
    except Exception:
        logging.warning(
            "Failed to load logging cofig from: %s", settings.LOGGING_CONFIG_PATH
        )
