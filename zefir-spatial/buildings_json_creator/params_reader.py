from collections import defaultdict
import json
from pathlib import Path

import pandas as pd


class Folders:
    technologies = "technologies"
    scenarios = "scenarios"
    data_reduction = "data_reduction"
    demand_profiles = "demand_profiles"


class Files:
    building = "buildings.json"
    zones = "zones.json"
    params = "params.json"
    capacity_factor = "capacity_factor.csv"
    baseline_expected_results = "baseline_expected_results.csv"
    cop_h_profile = "cop_h_profile.csv"
    cop_hw_profile = "cop_hw_profile.csv"


class TechFileAttr:
    name = "name"
    capex = "capex"
    opex = "opex"
    build_time = "build_time"
    life_time = "life_time"
    tech_type = "type"
    emissions = "emissions"
    energy_conversion_efficiency = "energy_conversion_efficiency"
    fuel = "fuel"
    var_cost = "var_cost"
    max_nom_power_global = "max_nom_power_global"
    base_nom_power_zonal = "base_nom_power_zonal"
    base_nom_power_global = "base_nom_power_global"
    thermo_efficiency = "thermo_efficiency"
    cost = "cost"
    capacity_factor = "capacity_factor"
    charge_efficiency = "charge_efficiency"
    cop = "cop"


def load_json(path: Path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def load_profile(path: Path):
    return pd.read_csv(path, header=None, index_col=0, parse_dates=True).squeeze('columns')


def load_demand_profiles(params_dir: Path):
    demand_profiles_dir = params_dir / Folders.demand_profiles
    demand = defaultdict(dict)
    for subfolder in demand_profiles_dir.iterdir():
        for profile_path in subfolder.iterdir():
            name = profile_path.stem
            series = load_profile(profile_path)
            series.name = name
            demand[subfolder.name][name] = series
    return demand


def load_technologies(params_dir):
    technology_dir = params_dir / Folders.technologies
    technologies = dict()
    for subfolder in technology_dir.iterdir():
        tech = load_json(subfolder / Files.params)
        capacity_factor_path = subfolder / Files.capacity_factor
        cop_h_profile_path = subfolder / Files.cop_h_profile
        cop_hw_profile_path = subfolder / Files.cop_hw_profile
        if capacity_factor_path.exists():
            tech[capacity_factor_path.stem] = load_profile(capacity_factor_path)
        if cop_h_profile_path.exists():
            tech[TechFileAttr.cop] = dict(
                heat=load_profile(cop_h_profile_path),
                heat_water=load_profile(cop_hw_profile_path),
            )

        technologies[tech[TechFileAttr.name]] = tech
    return technologies
