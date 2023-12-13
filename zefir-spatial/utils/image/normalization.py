from typing import Dict, Optional

import numpy as np
from PIL import Image

from feeder.kiut.layers import BACKGROUND_RGBA, LAYER_COLORS, LayerNames
from utils.image.color import is_background
from utils.image.distance import get_euklidesian_distance

# from utils.maps import _get_euklidesian_distance
from utils.typings import RGBA_T


def normalize_rgba_array(
    arr: np.ndarray,
    layer_to_color: Dict[LayerNames, RGBA_T],
    max_error: Optional[np.uint8] = None,
    background_rgba=BACKGROUND_RGBA,
) -> np.ndarray:
    """Normalize colors of KIUT layers to fit documentation values

    Args:
        arr (np.ndarray): array representing image (height,width,channels_no[4]):
                          red, green, blue, alpha
        max_rmse_error (int, optional): Above the limit it is treated as an outlier.
                                        Defaults to 10.

    Returns:
        np.ndarray: Normalized ndarray. The same size as the input `arr`
    """
    distance_list = []
    labels = {}
    for idx, (layer_name, rgba) in enumerate(layer_to_color.items()):
        distance = get_euklidesian_distance(arr, rgba)
        labels[layer_name] = idx
        distance_list.append(distance)
    distance_arr = np.stack(distance_list, 2)

    min_idx = np.argmin(distance_arr, 2)
    min_vals = np.min(distance_arr, 2)

    normarr = np.empty(arr.shape)
    normarr[:, :, :] = np.nan

    for layer_name, rgba in layer_to_color.items():
        idx = labels[layer_name]
        normarr[min_idx == idx] = rgba

    # Additoionaly bleach pixels that distance => THRESHOLD (treat these pixels as undefined, error is too big)
    if max_error:
        normarr[min_vals >= max_error] = background_rgba
    # filter background pixels
    normarr[is_background(arr)] = background_rgba

    assert not np.isnan(normarr).any(), "Nan values indicate wrong indexing"
    return normarr


def normalize_image(
    image: Image,
    layer_to_color: Dict[LayerNames, RGBA_T] = LAYER_COLORS,
    max_error: int = 255,
    background_rgba=BACKGROUND_RGBA,
):
    image = image.convert("RGBA")
    arr = np.array(image)
    normarr = normalize_rgba_array(arr, layer_to_color, max_error, background_rgba)
    return Image.fromarray(normarr.astype(np.uint8))
