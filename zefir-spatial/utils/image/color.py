from typing import Tuple

import numpy as np
from PIL import Image
from utils.typings import RGB_T

DEFAULT_TRANSPARENT_THRESHOLD = 100
DEFAULT_WHITE_THRESHOLD = (220, 220, 220)


def is_white(arr: np.ndarray, filter_value: RGB_T = DEFAULT_WHITE_THRESHOLD):
    return arr[:, :, :3].astype(int).sum(2) >= sum(filter_value)
    # white if red+blue+green >= 220 * 3


def is_transparent(arr: np.ndarray, filter_value: int = 100) -> np.ndarray:
    return arr[:, :, 3] <= filter_value  # alpha channel < 100


def is_background(
    arr: np.ndarray,
    white_threshold: RGB_T = DEFAULT_WHITE_THRESHOLD,
    transparent_threshold: int = DEFAULT_TRANSPARENT_THRESHOLD,
) -> np.ndarray:
    white = is_white(arr, white_threshold)
    transp = is_transparent(arr, transparent_threshold)
    return white | transp
