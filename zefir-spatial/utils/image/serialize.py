import io

from PIL import Image


def image_to_bytes(image: Image, format="PNG"):
    with io.BytesIO() as output:
        image.save(output, format=format)
        return output.getvalue()
