from dataclasses import dataclass
from pathlib import Path
from typing import Union


@dataclass
class Config:
    ceeb_path: Path
    bdot_path: Path
    zabytki_path: Union[Path, None]
    joined_file_name: str
    only_bdot_file_name: str
    output_path: Path = None
