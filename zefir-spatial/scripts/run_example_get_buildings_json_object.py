from pathlib import Path

from buildings_json_creator.build_dict import build_buildings_from_df
from buildings_json_creator.config_handler import load_config_from_json
from buildings_json_creator.get_df import read_from_csv, read_from_db
from buildings_json_creator.params_reader import load_demand_profiles, load_technologies

df = read_from_db("2212011")


# df = read_from_db('2417011')
config = load_config_from_json(
    "/home/kkrolikowski/projects/zefir-spatial/buildings_json_creator/default_config.json"
)
params_path = Path("/home/kkrolikowski/projects/longtermklastry/parameters/data/zywiec")
technologies = load_technologies(params_path)
profiles = load_demand_profiles(params_path)
buildings = build_buildings_from_df(df, technologies, profiles, config=config)
print(buildings[0])
