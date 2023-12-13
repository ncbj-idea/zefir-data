import numpy as np
from shapely.geometry import box
from PIL import Image


class GeomapRgbaArray:
    def __init__(
        self, array: np.ndarray, minx: float, miny: float, maxx: float, maxy: float
    ) -> None:
        self._array = array
        self.minx = minx
        self.miny = miny
        self.maxx = maxx
        self.maxy = maxy

    @property
    def array(self):
        return self._array

    @array.setter
    def array(self, arr: np.ndarray):
        if not isinstance(arr, np.ndarray):
            raise TypeError("self.array should be an arrayb type")
        if len(arr.shape) == 3:
            msg = "self.array should be 3 dimension array"
            raise ValueError(msg)
        if arr.shape[2] == 4:
            msg = (
                "self.array should be 3 dimension array that represents R,G,B and alpha"
                " channel"
            )
            raise ValueError(msg)
        self._array = arr

    @property
    def scale_x(self):
        return (self.maxx - self.minx) / self.array.shape[1]

    @property
    def scale_y(self):
        return (self.maxy - self.miny) / self.array.shape[0]

    def get_geom(self):
        return box(minx=self.minx, miny=self.miny, maxx=self.maxx, maxy=self.maxy)

    def x(self, col_idx: int):
        return self.minx + col_idx * self.scale_x

    def y(self, row_idx: int):
        return self.maxy - row_idx * self.scale_y

    def get_image(self):
        return Image.fromarray(self.array)
