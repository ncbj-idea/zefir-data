import logging
from typing import NamedTuple

import numpy as np
import pandas as pd

from buildings_json_creator.config_handler import MakeBuildingsConfig
from buildings_json_creator.params_reader import TechFileAttr

logger = logging.getLogger(__name__)


def _generate_address(row: NamedTuple):
    ulica = f"{row.ulica} " if row.ulica else ""
    numer_porzadkowy = str(row.numer_porzadkowy) if row.numer_porzadkowy else ""
    street = ulica + numer_porzadkowy
    address = {
        "city": row.miejscowosc,
        "district": "NaN",
        "lat": row.latitude_centroid,
        "lon": row.longitude_centroid,
        "street": street,
    }
    return address


def _validate_technology_names_in_config(config, technologies):
    if config.district_heating_technology_name not in technologies:
        raise KeyError(
            "Config key error for district_heating_technology_name:"
            f" {config.district_heating_technology_name} not exist in technologies"
        )
    if config.default_heat_source_name not in technologies:
        raise KeyError(
            "Config key error for default_heat_source_name:"
            f" {config.default_heat_source_name} not exist in technologies"
        )
    if config.default_heatwater_source_name not in technologies:
        raise KeyError(
            "Config key error for default_heatwater_source_name:"
            f" {config.default_heatwater_source_name} not exist in technologies"
        )
    for techname in config.default_connectable_technologies:
        if techname not in technologies:
            raise KeyError(
                "Config key error for default_connectable_technologies:"
                f" {techname} not exist in technologies"
            )
    if config.pv_technology_name not in technologies:
        raise KeyError(
            "Config key error for pv_technology_name:"
            f" {config.pv_technology_name} not exist in technologies"
        )


def _process_row(row, config: MakeBuildingsConfig, technologies, profiles):
    funkcja_ogolna = str(row.funkcja_ogolna)
    building_type = config.dict_funckja_ogolna_typ_budynku[str(row.funkcja_ogolna)]
    if row.heat_connected:
        now_tech_heat = config.district_heating_technology_name
        now_tech_cwu = config.district_heating_technology_name
    else:
        now_tech_heat = config.default_heat_source_name
        now_tech_cwu = config.default_heatwater_source_name

    heat_and_cwu_connectable_techs = [*config.default_connectable_technologies]
    if row.gas_connected:
        heat_and_cwu_connectable_techs.append(config.gas_technology_name)

    if np.isfinite(row.pow_uzytkowa_m2):
        powierzchnia_uzytkowa = row.pow_uzytkowa_m2
    elif np.isfinite(row.pow_obrysu_m2):
        logger.warning(
            f"Not finite value of pow_uzytkowa_m2 for building id: %s. Value"
            f" will be replaced by pow_obrysu_m2.",
            row.id,
        )
        powierzchnia_uzytkowa = row.pow_obrysu_m2
    else:
        raise ValueError(
            'f"Not finite value of pow_uzytkowa_m2 for building id: %s. Cannot be'
            " replaced by pw_obrysu_m2.",
            row.id,
        )
    # zapotrzebowanie uzytkowe na cieplo, cwu, en. elektryczna per m2
    eu_cieplo_m2 = config.dict_funkcja_ogolna_energia_uzytkowa_cieplo[funkcja_ogolna]
    eu_cwu_m2 = config.dict_funkcja_ogolna_energia_uzytkowa_cwu[funkcja_ogolna]
    demand_electric_m2 = config.dict_funkcja_ogolna_energia_elektryczna[funkcja_ogolna]
    # sprawnosic urzadzen
    eff_cieplo = technologies[now_tech_heat][TechFileAttr.energy_conversion_efficiency][
        "heat"
    ][building_type]
    eff_cwu = technologies[now_tech_cwu][TechFileAttr.energy_conversion_efficiency][
        "heat_water"
    ]

    heat_uzytkowa = powierzchnia_uzytkowa * eu_cieplo_m2
    cwu_uzytkowa = powierzchnia_uzytkowa * eu_cwu_m2
    heat_koncowa = (heat_uzytkowa) / eff_cieplo
    cwu_koncowa = (cwu_uzytkowa) / eff_cwu
    electric = powierzchnia_uzytkowa * demand_electric_m2

    demant_heat_uzytkowa_profile = profiles["heat"][building_type] * heat_uzytkowa
    demand_cwu_uzytkowe_profile = profiles["heat_water"][building_type] * cwu_uzytkowa
    excluded_types = {"grid"}
    # TODO biblioteka longtermklastry wymusza zeby w slowniku byly 0 wartosci dla klucza base_nom_power_zonal
    base_nom_power_zonal = {
        techname: 0
        for techname, tech_data in technologies.items()
        if tech_data[TechFileAttr.tech_type] not in excluded_types
    }

    if now_tech_heat == now_tech_cwu:
        # gdy cwu i heat to ta sama technologia, to nalezy dodac profile heat + cwu i wyznaczyć max
        # TODO zweryfikowac
        max_demand_peak = (
            demant_heat_uzytkowa_profile + demand_cwu_uzytkowe_profile
        ).max()

        base_nom_power_zonal[now_tech_heat] = max_demand_peak
    else:
        base_nom_power_zonal = {
            now_tech_heat: demant_heat_uzytkowa_profile.max(),
            now_tech_cwu: demand_cwu_uzytkowe_profile.max(),
        }
    pv_max_power = (
        config.pv_max_kw_on_m2 * row.pow_obrysu_m2
        if row.pow_obrysu_m2 >= config.pv_minimal_roof_area_m2
        else 0
    )
    building = {
        "type": building_type,
        "address": _generate_address(row),
        "id": row.id,
        "usable_area": powierzchnia_uzytkowa,
        "yearly_energy_demand": {
            "electric": electric,
            "heat": heat_koncowa,
            "heat_water": cwu_koncowa,
        },
        "now_tech": {"heat": now_tech_heat, "heat_water": now_tech_cwu},
        "base_nom_power_zonal": {
            name: power * 1.005
            for name, power in base_nom_power_zonal.items()  # TODO 1.005 to solve numerical issues?
        },
        "connectable_techs": {
            "heat": heat_and_cwu_connectable_techs,
            "heat_water": heat_and_cwu_connectable_techs,
        },
        "max_nom_power_zonal": {config.pv_technology_name: pv_max_power},
    }
    return building


def build_buildings_from_df(
    df: pd.DataFrame, technologies, profiles, config: MakeBuildingsConfig
) -> dict:
    buildings = []
    _validate_technology_names_in_config(config, technologies)
    for row in df.itertuples(index=True):
        building = _process_row(row, config, technologies, profiles)
        buildings.append(building)
    return buildings
