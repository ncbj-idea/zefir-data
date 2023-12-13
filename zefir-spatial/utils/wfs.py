import xml.etree.ElementTree as ET
from urllib.parse import parse_qsl, urlencode

import requests


def capabilities_url(service_url):
    """Port from owslib library.
    Return normalized GetCapabilities request url without specifying version!
    Compare with: owslib.feature.common.WFSCapabilitiesReader
    """
    qs = []
    if service_url.find("?") != -1:
        qs = parse_qsl(service_url.split("?")[1])

    params = [x[0] for x in qs]

    if "service" not in params:
        qs.append(("service", "WFS"))
    if "request" not in params:
        qs.append(("request", "GetCapabilities"))

    urlqs = urlencode(tuple(qs))
    return service_url.split("?")[0] + "?" + urlqs


def get_wfs_version(url: str):
    """get version from default GetCapabilities request"""
    normurl = capabilities_url(url)
    res = requests.get(normurl)
    capabilities_xml_root = ET.fromstring(res.text)
    version = capabilities_xml_root.attrib["version"]
    return version
