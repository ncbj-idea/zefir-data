import concurrent.futures
import logging
import threading
import time
from functools import partial
from typing import List, Sequence

from owslib.wms import WebMapService
from requests.exceptions import ConnectionError, ReadTimeout
from retrying import retry

logger = logging.getLogger(__name__)

MAX_RETRIES = 10
WAIT_MS = 0
TIMEOUT = 300

Bbox_T = List[float]


class WebMapServiceBulk:
    thread_local_storage = threading.local()

    def __init__(self, url, version, max_workers: int = 10, timeout=TIMEOUT) -> None:
        self.url = url
        self.version = version
        self.max_workers = max_workers
        self.timeout = timeout

    @property
    def wms(self):
        if not hasattr(self.thread_local_storage, "wms"):
            wms = WebMapService(self.url, self.version, timeout=self.timeout)
            self.thread_local_storage.wms = wms
        return self.thread_local_storage.wms

    @retry(
        wait_fixed=WAIT_MS,
        stop_max_attempt_number=MAX_RETRIES,
        retry_on_exception=lambda exception: isinstance(exception, (ConnectionError,)),
    )  # TODO implement retry_call to use dynamic params https://pypi.org/project/retry/
    def _send_request(self, bbox, *args, **kwargs):
        return self.wms.getmap(*args, bbox=bbox, **kwargs)

    def _get_single_map(self, bbox: Bbox_T, *args, **kwargs):
        result = {"bbox": bbox}
        try:
            res = self._send_request(*args, bbox=bbox, **kwargs)
            url = res.geturl()
            logger.debug(
                "(%s) Responded in (%s) sec from %s",
                res._response.status_code,
                res._response.elapsed.total_seconds(),
                url,
            )
            result["url"] = url
            res._response.raise_for_status()
            result["image"] = res.read()
        except Exception as e:
            result["error"] = str(e)
            logger.exception("Exception occured for bbox %s", bbox)
        return result

    def getmaps(self, bboxes: Sequence[Bbox_T], *args, **kwargs):

        logger.info(
            "%d requests will be send with max connections = %d",
            len(bboxes),
            self.max_workers,
        )

        func = partial(self._get_single_map, *args, **kwargs)

        with concurrent.futures.ThreadPoolExecutor(
            max_workers=self.max_workers
        ) as executor:
            res = executor.map(func, bboxes)
        return res


if __name__ == "__main__":
    bbox = [705400.0, 233800.0, 705500.0, 233900.0]
    bboxes = [bbox] * 10
    start_time = time.time()
    wms = WebMapServiceBulk(
        "https://integracja.gugik.gov.pl/cgi-bin/KrajowaIntegracjaUzbrojeniaTerenu",
        "1.3.0",
        max_workers=2,
    )
    kwargs = dict(
        layers=["przewod_gazowy"],
        size=(100, 100),  # TODO hardcoded
        srs="EPSG:2180",
        format="image/jpeg",
    )
    wms.getmaps(bboxes, **kwargs)
    duration = time.time() - start_time
    print(f"Downloaded {len(bboxes)} in {duration} seconds")
