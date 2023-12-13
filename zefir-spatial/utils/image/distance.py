import numpy as np
from utils.typings import RGBA_T


def get_euklidesian_distance(arr: np.ndarray, rgba: RGBA_T):
    arr = arr.astype(float)
    red, green, blue, _ = rgba
    distance = np.sqrt(
        (arr[:, :, 0] - red) ** 2
        + (arr[:, :, 1] - green) ** 2
        + (arr[:, :, 2] - blue) ** 2
    )
    return distance / np.sqrt(3)  # as return we get values from 0 ... 255


def get_redmean_distance(arr: np.ndarray, rgba: RGBA_T):
    """Implements `redmean` distance: https://en.wikipedia.org/wiki/Color_difference#sRGB"""
    arr = arr.astype(float)
    red, green, blue, _ = rgba
    r_ = (arr[:, :, 0] + red) / 2
    rcorr = 2 + r_ / 256
    gcorr = 4
    bcorr = 2 + (256 - r_) / 256
    distance = np.sqrt(
        rcorr * (arr[:, :, 0] - red) ** 2
        + gcorr * (arr[:, :, 1] - green) ** 2
        + bcorr * (arr[:, :, 2] - blue) ** 2
    )
    return distance / np.sqrt(rcorr + gcorr + bcorr)  # get values from 0 ... 255


def get_max_distance(arr: np.ndarray, rgba: RGBA_T):
    # as return we get values from 0 ... 255
    return abs((arr[:, :, 0:3] - rgba[0:3])).max(2)
