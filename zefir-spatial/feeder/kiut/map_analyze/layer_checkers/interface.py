from abc import ABC, abstractmethod
from typing import List

import numpy as np
from feeder.kiut.layers import LayerNames

ExistingLayers = List[LayerNames]


class LayerChecker(ABC):
    @abstractmethod
    def get_existing_layers(self, array: np.ndarray) -> ExistingLayers:
        pass
