import json
from pathlib import Path
from typing import Dict, List

from config import settings
from pydantic import BaseSettings, HttpUrl


class MakeBuildingsConfig(BaseSettings):
    dict_funckja_ogolna_typ_budynku: Dict[str, str]
    dict_funkcja_ogolna_energia_uzytkowa_cieplo: Dict[str, float]
    dict_funkcja_ogolna_energia_uzytkowa_cwu: Dict[str, float]
    dict_funkcja_ogolna_energia_elektryczna: Dict[str, float]
    default_heat_source_name: str
    default_heatwater_source_name: str
    default_connectable_technologies: List[str]
    gas_technology_name: str
    district_heating_technology_name: str
    pv_technology_name: str
    pv_max_kw_on_m2: float
    pv_minimal_roof_area_m2: float


DEFAULT_CONFIG_PATH = Path(__file__).parent / "default_config.json"


def load_config_from_json(path_to_config: Path):
    with open(path_to_config, "r") as f:
        config = json.load(f)
    return MakeBuildingsConfig(**config)