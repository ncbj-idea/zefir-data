import logging

from feeder.kiut.layers import AllowedLayerNames
from feeder.kiut.map_analyze.layer_checkers.check_by_color import CheckByLayerColor
from feeder.kiut.map_analyze.layer_checkers.check_by_not_blank_pixels import (
    CheckByNotBlankPixels,
)
from feeder.config_schemas.kiut_config import (
    PolyganizationMethods_T,
    PolygonizationMethodNames,
)

logger = logging.getLogger(__name__)

GRID_EXISTANCE_THRESHOLD = 0.005


def get_grid_checker(layer_name: str, params: PolyganizationMethods_T):
    """Factory for Polygonizer"""
    if params.name == PolygonizationMethodNames.NOT_BLANK_MAP.value:
        return CheckByNotBlankPixels(
            layer=AllowedLayerNames[layer_name],
            **params.dict(),
        )
    elif params.name == PolygonizationMethodNames.ANALYZE_COLORS_ON_MAP.value:
        return CheckByLayerColor(**params.dict())
    else:
        raise KeyError("Unexpected polyganization method %s" % params.name)
