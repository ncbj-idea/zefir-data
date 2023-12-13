import argparse
import json
import sys
from pathlib import Path

from buildings_json_creator.build_dict import build_buildings_from_df
from buildings_json_creator.config_handler import DEFAULT_CONFIG_PATH, load_config_from_json
from buildings_json_creator.get_df import read_from_db
from buildings_json_creator.params_reader import load_demand_profiles, load_technologies


def parse_args(args):
    parser = argparse.ArgumentParser(
        description=(
            "Generate buildings.json from spatial data (from the database) to use with"
            " longtermklastry lib"
        )
    )
    parser.add_argument(
        "terc",
        type=str,
        help="TERC code of a given municipiality",
    )
    parser.add_argument(
        "params",
        type=Path,
        help="Directory with params of municipality",
    )
    parser.add_argument(
        "--out-filepath",
        dest="out_filepath",
        required=False,
        type=Path,
        default="buildings.json",
        help="Path, where the JSON file will be saved",
    )
    parser.add_argument(
        "--config-filepath",
        dest="config_filepath",
        required=False,
        type=Path,
        default=DEFAULT_CONFIG_PATH,
        help="Path, to file with configuration",
    )
    return parser.parse_args(args)


def main(args=None):
    if not args:
        args = sys.argv[1:]
    pargs = parse_args(args)
    df = read_from_db(pargs.terc)
    config = load_config_from_json(pargs.config_filepath)
    technologies = load_technologies(pargs.params)
    profiles = load_demand_profiles(pargs.params)
    buildings = build_buildings_from_df(df, technologies, profiles, config=config)
    with open(pargs.out_filepath, "w", encoding="utf8") as json_file:
        json.dump(
            buildings,
            json_file,
            indent=2,
            sort_keys=True,
            ensure_ascii=False,
            allow_nan=True,
        )


if __name__:
    # in cmd: python -m buildings_json_creator 2417011 ~/projects/longtermklastry/parameters/data/zywiec --out-filepath buildings_new.json
    main()
