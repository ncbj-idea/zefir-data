from feeder.config_schemas.kiut_config import (
    AnalyzeColorsOnMapConfig,
    KiutConfig,
    WmsConfig,
)


class DefaultModes:
    SHOULD_BE_MOST_ACCURATE = KiutConfig(
        wms=WmsConfig(bbox_size=500, image_size=2 * 500),
        number_of_slices_of_image_side=100 // 2,
    )

    SHOULD_BE_OPTIMAL = KiutConfig(
        wms=WmsConfig(bbox_size=1000, image_size=1 * 1000),
        number_of_slices_of_image_side=1 * 100,
    )

    SHOULD_WORK_FOR_PROBLEMATIC_MZK_CITIES = KiutConfig(
        wms=WmsConfig(bbox_size=200, image_size=1000, max_connections=2),
        number_of_slices_of_image_side=20,
        polygonization=AnalyzeColorsOnMapConfig(),
    )
