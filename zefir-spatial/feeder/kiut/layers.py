from enum import Enum


class AllowedLayerNames(str, Enum):
    przewod_wodociagowy = "przewod_wodociagowy"
    przewod_kanalizacyjny = "przewod_kanalizacyjny"
    przewod_cieplowniczy = "przewod_cieplowniczy"
    przewod_gazowy = "przewod_gazowy"
    przewod_telekomunikacyjny = "przewod_telekomunikacyjny"
    przewod_elektroenergetyczny = "przewod_elektroenergetyczny"
    przewod_niezidentyfikowany = "przewod_niezidentyfikowany"
    przewod_specjalny = "przewod_specjalny"


class LayerNames(Enum):
    przewod_wodociagowy = 1
    przewod_kanalizacyjny = 2
    przewod_cieplowniczy = 3
    przewod_gazowy = 4
    przewod_telekomunikacyjny = 5
    przewod_elektroenergetyczny = 6
    przewod_niezidentyfikowany = 7
    przewod_specjalny = 8


BACKGROUND_NAME = "BACKGROUND"
BACKGROUND_RGBA = (0, 0, 0, 0)

LAYER_COLORS = {
    AllowedLayerNames.przewod_wodociagowy: (32, 32, 160, 255),
    AllowedLayerNames.przewod_kanalizacyjny: (128, 96, 32, 255),
    AllowedLayerNames.przewod_cieplowniczy: (210, 0, 210, 255),
    AllowedLayerNames.przewod_gazowy: (220, 220, 50, 255),
    AllowedLayerNames.przewod_telekomunikacyjny: (255, 128, 64, 255),
    AllowedLayerNames.przewod_elektroenergetyczny: (255, 0, 0, 255),
    AllowedLayerNames.przewod_niezidentyfikowany: (32, 32, 32, 255),
}


LAYERS_COLORS_LAW = {
    AllowedLayerNames.przewod_wodociagowy: (0, 0, 255, 255),
    AllowedLayerNames.przewod_kanalizacyjny: (128, 51, 0, 255),
    AllowedLayerNames.przewod_cieplowniczy: (210, 0, 210, 255),
    AllowedLayerNames.przewod_gazowy: (191, 191, 0, 255),
    AllowedLayerNames.przewod_telekomunikacyjny: (255, 145, 0, 255),
    AllowedLayerNames.przewod_elektroenergetyczny: (255, 0, 0, 255),
    AllowedLayerNames.przewod_niezidentyfikowany: (0, 0, 0, 255),
}
