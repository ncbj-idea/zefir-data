import logging

import numpy as np
from feeder.kiut.layers import AllowedLayerNames
from feeder.kiut.map_analyze.layer_checkers.interface import (
    ExistingLayers,
    LayerChecker,
)
from utils.image.color import is_background

logger = logging.getLogger(__name__)


class CheckByNotBlankPixels(LayerChecker):
    def __init__(self, layer: AllowedLayerNames, grid_existance_threshold: float):
        self.grid_existance_threshold = grid_existance_threshold
        self.layer = layer

    def get_existing_layers(self, array: np.ndarray) -> ExistingLayers:
        grid_exist = ~self._get_blank_pixels(array)
        is_grid = np.sum(grid_exist) / grid_exist.size >= self.grid_existance_threshold
        return [self.layer] if is_grid else []

    @staticmethod
    def _get_blank_pixels(arr: np.ndarray) -> np.ndarray:
        return is_background(arr)
