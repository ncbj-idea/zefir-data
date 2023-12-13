import logging
from typing import Dict, Optional, Tuple

import numpy as np
from feeder.kiut.layers import BACKGROUND_RGBA, LAYER_COLORS, LayerNames
from feeder.kiut.map_analyze.layer_checkers.interface import (
    ExistingLayers,
    LayerChecker,
)
from PIL import Image
from utils.image.normalization import normalize_rgba_array
from utils.typings import RGBA_T

logger = logging.getLogger(__name__)


class CheckByLayerColor(LayerChecker):
    def __init__(
        self,
        layer_colors: Optional[Dict[LayerNames, RGBA_T]] = None,
        grid_existance_threshold: float = 0,
        max_error: Optional[np.uint8] = None,
        background_rgba: RGBA_T = BACKGROUND_RGBA,
    ):
        if not layer_colors:
            layer_colors = LAYER_COLORS
        self.layer_colors = layer_colors
        self.grid_existance_threshold = grid_existance_threshold
        self.max_error = max_error
        self.background_rgba = background_rgba

    def get_existing_layers(self, array: np.ndarray) -> ExistingLayers:
        normarr = normalize_rgba_array(
            arr=array,
            layer_to_color=self.layer_colors,
            max_error=self.max_error,
            background_rgba=self.background_rgba,
        )
        grid_existance = self._get_layer_existance_indicator(normarr)
        return [layer for layer, exist in grid_existance.items() if exist]

    def _get_layer_existance_indicator(self, arr: np.ndarray):
        heigh, width, _ = arr.shape
        grid_size = self._count_pixels_in_layers(arr)
        assert (
            self._get_number_of_blank_pixels(arr) + sum(grid_size.values())
            == heigh * width
        )
        grid_existance = {}
        for layer, count_of_pixels in grid_size.items():
            grid_existance[layer] = (
                count_of_pixels / (heigh * width) >= self.grid_existance_threshold
            )
        return grid_existance

    def _count_pixels_in_layers(self, arr: np.ndarray):
        grid_size = {}
        for layer in self.layer_colors:
            r, g, b, a = self.layer_colors[layer]
            grid_size[layer] = (
                (arr[:, :, 0] == r)
                & (arr[:, :, 1] == g)
                & (arr[:, :, 2] == b)
                & (arr[:, :, 3] == a)
            ).sum()
        return grid_size

    def _get_number_of_blank_pixels(self, arr):
        r, g, b, a = self.background_rgba
        return (
            (arr[:, :, 0] == r)
            & (arr[:, :, 1] == g)
            & (arr[:, :, 2] == b)
            & (arr[:, :, 3] == a)
        ).sum()


def process(image: Image):
    image = image.convert("RGBA")
    arr = np.array(image)
    checker = CheckByLayerColor()
    return checker.get_existing_layers(arr)


if __name__ == "__main__":
    img = Image.open("KrajowaIntegracjaUzbrojeniaTerenu_14_1000.png")
    import time

    start = time.time()
    grid_existance = process(img)

    end = time.time()
    print(end - start)
    print(grid_existance)
    pass
