import logging

import requests
from retrying import retry

from utils.wms import MAX_RETRIES, TIMEOUT, WAIT_MS

logger = logging.getLogger(__name__)


@retry(
    wait_fixed=WAIT_MS,
    stop_max_attempt_number=MAX_RETRIES,
    retry_on_exception=lambda exception: isinstance(exception, (ConnectionError,)),
)  # TODO implement retry_call to use dynamic params https://pypi.org/project/retry/
def get_content_from_remote(url: str):
    logger.debug("Send request to %s.", url)

    response = requests.get(url, timeout=TIMEOUT)
    logger.debug("Response %d from %s.", response.status_code, url)

    response.raise_for_status()
    return response.content
