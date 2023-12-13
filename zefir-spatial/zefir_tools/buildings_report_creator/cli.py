from argparse import ArgumentParser
from pathlib import Path


def get_parser():
    parser = ArgumentParser(description="Run to_excel converter")

    parser.add_argument(
        "-o",
        "--outpath",
        help="global path to generated excel file (.XLSX)",
        type=Path,
        required=False,
    )
    parser.add_argument(
        "-t", "--terc", help="TERYT number of specified city", type=str, required=True
    )
    return parser
