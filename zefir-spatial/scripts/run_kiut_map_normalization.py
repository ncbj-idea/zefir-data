from pathlib import Path

from PIL import Image

from config import ROOT_DIR
from utils.image.normalization import normalize_image

img = Image.open(ROOT_DIR / "data" / "kiut_map_example.png")
imgn = normalize_image(img, max_error=25)
path = Path.cwd() / "norm.png"
print("Image saved to ", path)
imgn.save(path)
