import logging
import subprocess
from typing import Optional

from config import settings

logger = logging.getLogger(__name__)


class Ogr2OgrCaller:
    def __init__(
        self,
        tablename: str,
        layer_name: str,
        replace: bool = True,
        layer_type: Optional[str] = "PROMOTE_TO_MULTI",
        fixed_axis_order: bool = False,
    ):
        self.tablename = tablename
        self.layer_name = layer_name
        self.layer_type = layer_type
        self.replace = replace
        self.fixed_axis_order = fixed_axis_order

    # def __call__(self, source, source_crs: Optional[str] = None):
    def __call__(self, source):
        db_params = (
            f"PG:host={settings.POSTGRES_HOST_ADDRESS} "
            f"user={settings.POSTGRES_USER} "
            f"port={settings.POSTGRES_HOST_PORT} "
            f"password={settings.POSTGRES_PASSWORD} "
            f"dbname={settings.POSTGRES_DB}"
        )

        cmd = [
            "ogr2ogr",
            "-f",
            "PostgreSQL",
            db_params,
            source,
            "-nln",
            self.tablename,
            "-forceNullable",
            "-lco",
            "PRECISION=no",
            self.layer_name,
            "-oo",
            "FORCE_SRS_DETECTION=YES",
        ]
        if self.layer_type:
            cmd += ["-nlt", self.layer_type]
        if self.replace:
            cmd += ["-overwrite"]
        else:
            cmd += ["-append", "-update"]
        if self.fixed_axis_order:
            cmd += ["-oo", "INVERT_AXIS_ORDER_IF_LAT_LONG=NO"]  # per dedault is `YES`

        # if source_crs:
        #     cmd += ["-a_srs", source_crs]

        # logger.debug('Call ogr2ogr statement:\n"%s"', " ".join(cmd)) # Todo: fix it, passwords are shown as a plain text
        try:
            output = subprocess.run(cmd, capture_output=True, text=True, check=True)
        except subprocess.CalledProcessError as e:
            logger.exception(
                "An error occured during ogr2ogr call with"
                " context\nstdderr:\n%sstdout:\n%sreturn code: %s",
                e.stderr,
                e.stdout,
                e.returncode,
            )
            raise
        if output.stderr:
            logger.warning("Warning: %s %s", output.stderr, output.stdout)
