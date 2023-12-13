import datetime
import io
import re

import pandas as pd
from owslib.wms import WebMapService
from PIL import Image

wms_url = "https://integracja.gugik.gov.pl/cgi-bin/KrajowaIntegracjaUzbrojeniaTerenu"

wms = WebMapService(wms_url, version="1.3.0")

real_x = 705400.0
real_y = 233800.0

real_deltas = [100, 500, 1000]
# real_deltas = [500, 1000]
image_sizes = range(10, 4150, 10)
image_sizes = range(10, 50, 10)

result = []
for real_size in real_deltas:
    for image_size in image_sizes:
        bbox = bbox = [real_x, real_y, real_x + real_size, real_y + real_size]
        size = (image_size, image_size)

        it_result = {
            "image_size": image_size,
            "real_size": real_size,
        }

        try:
            res = wms.getmap(
                layers=["przewod_gazowy"],
                size=size,
                srs="EPSG:2180",
                bbox=bbox,
                format="image/jpeg",
            )
            image = Image.open(io.BytesIO(res.read()))
            url = res.geturl()
            it_result |= {
                "is_gass": len(image.getcolors()) > 1,
                "url": res.geturl(),
            }
            pattern = r"^.*(BBOX|bbox)=(?P<x_start>[\d.]+),(?P<y_start>[\d.]+),(?P<x_end>[\d.]+),(?P<y_end>[\d.]+).*$"
            match = re.match(pattern, url)
            delta_x_from_api = float(match["x_end"]) - float(match["x_start"])
            delta_y_from_api = float(match["y_end"]) - float(match["y_start"])
            it_result |= {
                "delta_x_from_api": delta_x_from_api,
                "delta_y_from_api": delta_y_from_api,
            }

        except Exception as e:
            it_result |= {"error": str(e)}
        result.append(it_result)
        print(it_result)

print("saving to excel")
df = pd.DataFrame(result)
df.to_excel(f'{datetime.datetime.now().strftime("%Y%m%d%H%M")}_test.xlsx')
