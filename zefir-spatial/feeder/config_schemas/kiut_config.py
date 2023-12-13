from abc import abstractmethod
from enum import Enum
from typing import Dict, Tuple, Union

from feeder.kiut.layers import LAYER_COLORS, AllowedLayerNames
from pydantic import BaseSettings
from utils.typings import RGBA_T


class PolygonizationMethodNames(str, Enum):
    NOT_BLANK_MAP = "NOT_BLANK_MAP"
    ANALYZE_COLORS_ON_MAP = "ANALYZE_COLORS_ON_MAP"


class IPolyganizationMethods(BaseSettings):
    @property
    @abstractmethod
    def name(self):
        pass


class NotBlankMapConfig(BaseSettings):
    grid_existance_threshold: float = 0.005

    @property
    def name(self):
        return PolygonizationMethodNames.NOT_BLANK_MAP.value


class AnalyzeColorsOnMapConfig(BaseSettings):
    grid_existance_threshold: float = 0.005
    background_rgba: RGBA_T = (0, 0, 0, 0)
    layer_colors: Dict[AllowedLayerNames, RGBA_T] = LAYER_COLORS

    @property
    def name(self):
        return PolygonizationMethodNames.ANALYZE_COLORS_ON_MAP.value


PolyganizationMethods_T = Union[NotBlankMapConfig, AnalyzeColorsOnMapConfig]

KIUT_URL = "https://integracja.gugik.gov.pl/cgi-bin/KrajowaIntegracjaUzbrojeniaTerenu"


class WmsConfig(BaseSettings):
    bbox_size: int = 1000
    image_size: int = 1000
    max_connections: int = 20
    url: str = KIUT_URL
    version: str = "1.3.0"
    srid: int = 2180  # ask server for this srid


class KiutConfig(BaseSettings):

    number_of_slices_of_image_side: int = 100
    grid_existance_threshold: float = 0.005
    polygonization: PolyganizationMethods_T = NotBlankMapConfig()
    wms: WmsConfig = WmsConfig()

    # class Config:
    #     use_enum_values = True


class KiutImportParams(BaseSettings):
    terc: str
    config: KiutConfig = KiutConfig()
    layers: Tuple[AllowedLayerNames, ...] = (
        AllowedLayerNames.przewod_cieplowniczy.value,
        AllowedLayerNames.przewod_gazowy.value,
    )

    # class Config:
    # use_enum_values = True
