from pathlib import Path
from typing import Dict

import numpy as np
import pandas as pd

from zefir_tools.constants import (
    BUD_UWZGLEDNIANY_POWYZEJ,
    CZY_OGRZEWANY,
    FUNKCJA_OGOLNA,
    FUNKCJA_SZCZEGOLOWA,
    FUNKCJA_SZCZEGOLOWA_1,
    FUNKCJA_SZCZEGOLOWA_2,
    FUNKCJA_SZCZEGOLOWA_3,
    M2_MIN_DO_SIECI,
    MIN_POW_ZABUD,
    NAZWA_PARAMETRU,
    ODLEGLOSC_OD_SIECI,
    PARAMETRY,
    PODL_DO_GAZ_I_SYSTEM_GS,
    POW_POWYZEJ,
    POW_UZYT_OGRZ_PARTERU_Z_WYLACZENIEM,
    POW_UZYTKOWA_OGRZEWANA,
    POZA_PODL_DO_SIECI_GAZ_I_CIEP_N,
    PROCENT_POWIERZCHNI_OGRZEWANYCH_BUDYNKOW,
    QUERY_GAS_DISTANCE,
    QUERY_HEAT_DISTANCE,
    QUERY_LICZBA_KONDYGNACJI,
    QUERY_POW_OBRYSU_M2,
    TYLKO_PODL_DO_GAZU_G,
    TYLKO_PODL_DO_SYSTEM_S,
    WSPOLCZYNNIK_POWIERZCHNI_UZYTKOWEJ_DO_POWIERZCHNI_ZABUDOWY,
    ZALEZNE_OD_FUNKCJI_OGOLNEJ,
    ZALEZNE_OD_FUNKCJI_SZCZEGOLOWEJ,
)


def get_data_from_db(terc: str, engine) -> pd.DataFrame:
    stm = (
        f"SELECT *, st_astext(geom) geom_wkt FROM get_gis_data_for_given_terc('{terc}')"
    )
    data = pd.read_sql(stm, engine)

    data[FUNKCJA_SZCZEGOLOWA_1] = data[FUNKCJA_SZCZEGOLOWA].apply(
        lambda x: _get_nth_element_or_return_none_if_not_exist(x, 0)
    )
    data[FUNKCJA_SZCZEGOLOWA_2] = data[FUNKCJA_SZCZEGOLOWA].apply(
        lambda x: _get_nth_element_or_return_none_if_not_exist(x, 1)
    )
    data[FUNKCJA_SZCZEGOLOWA_3] = data[FUNKCJA_SZCZEGOLOWA].apply(
        lambda x: _get_nth_element_or_return_none_if_not_exist(x, 2)
    )
    data["other"] = data["other"].apply(str)
    data["other"] = data["other"].apply(lambda x: x[1: -1])
    return data


def _get_split_dict(dct: dict) -> Dict[str, int]:
    dict_result = {k: v[0] for k, v in dct.items()}

    return dict_result


def get_parameters_from_template(path) -> Dict[str, int]:
    df_params = pd.read_excel(path, sheet_name=PARAMETRY)
    dict_temp = df_params.set_index(NAZWA_PARAMETRU).T.to_dict(orient="list")
    result = _get_split_dict(dict_temp)

    return result


def _get_nth_element_or_return_none_if_not_exist(_list: list, nth: int):
    """Return nth element from list or return none if out of range"""
    try:
        return _list[nth]
    except IndexError:
        return None


def create_buildings_report(engine, terc: str, template_path: Path) -> pd.DataFrame:
    """
    Calculation and processing buildings' data for specified city.
    :param terc: TERYT code of specified city,
    :param template_path: input path to Template.xlsx file,
    which contains funkcja_szczegolowa's conditions and requered parameters
    :return:
    return DataFrame with extended buildings' data.
    """
    params = get_parameters_from_template(template_path)
    city_data = get_data_from_db(terc, engine)

    with pd.ExcelFile(template_path) as reader:
        df_funkcja_szczegolowa = pd.read_excel(
            reader,
            sheet_name=ZALEZNE_OD_FUNKCJI_SZCZEGOLOWEJ,
        )
        df_funkcja_ogolna = pd.read_excel(
            reader,
            sheet_name=ZALEZNE_OD_FUNKCJI_OGOLNEJ,
        )
    df = get_extended_buildings_data(
        city_data, df_funkcja_szczegolowa, df_funkcja_ogolna, params
    )

    return df


def get_extended_buildings_data(
    city_data, df_funkcja_szczegolowa, df_funkcja_ogolna, params
) -> pd.DataFrame:
    df = pd.merge(
        city_data.astype({FUNKCJA_OGOLNA: str}),
        df_funkcja_ogolna.astype({FUNKCJA_OGOLNA: str}),
        how="left",
        on=FUNKCJA_OGOLNA,
    )
    dfn = df.drop(columns=[FUNKCJA_SZCZEGOLOWA, CZY_OGRZEWANY])
    dfn = pd.merge(
        dfn.astype({FUNKCJA_SZCZEGOLOWA_1: str}),
        df_funkcja_szczegolowa.astype({FUNKCJA_SZCZEGOLOWA: str}),
        how="left",
        left_on=FUNKCJA_SZCZEGOLOWA_1,
        right_on=FUNKCJA_SZCZEGOLOWA,
    )

    if dfn.duplicated("id").any():
        raise ValueError("Some duplicated buildings after merging")

    dfn[POW_UZYTKOWA_OGRZEWANA] = (
        dfn[QUERY_POW_OBRYSU_M2]
        * dfn[QUERY_LICZBA_KONDYGNACJI]
        * dfn[WSPOLCZYNNIK_POWIERZCHNI_UZYTKOWEJ_DO_POWIERZCHNI_ZABUDOWY]
        * dfn[PROCENT_POWIERZCHNI_OGRZEWANYCH_BUDYNKOW]
    )
    dfn[BUD_UWZGLEDNIANY_POWYZEJ] = (
        (dfn[POW_UZYTKOWA_OGRZEWANA] > params[MIN_POW_ZABUD])
        | (dfn[PROCENT_POWIERZCHNI_OGRZEWANYCH_BUDYNKOW] == 0.4)
    ).astype(int)

    dfn[POW_POWYZEJ] = np.where(
        dfn[BUD_UWZGLEDNIANY_POWYZEJ] == 1, dfn[POW_UZYTKOWA_OGRZEWANA], 0
    )
    dfn[POW_UZYT_OGRZ_PARTERU_Z_WYLACZENIEM] = (
        dfn[POW_POWYZEJ] / dfn[QUERY_LICZBA_KONDYGNACJI]
    )
    dfn[PODL_DO_GAZ_I_SYSTEM_GS] = (
        (dfn[QUERY_GAS_DISTANCE] < params[ODLEGLOSC_OD_SIECI])
        & (dfn[QUERY_HEAT_DISTANCE] < params[ODLEGLOSC_OD_SIECI])
        & (dfn[POW_UZYTKOWA_OGRZEWANA] > params[M2_MIN_DO_SIECI])
    )
    dfn[TYLKO_PODL_DO_GAZU_G] = (
        dfn[QUERY_GAS_DISTANCE] < params[ODLEGLOSC_OD_SIECI]
    ) & ~dfn[PODL_DO_GAZ_I_SYSTEM_GS]
    dfn[TYLKO_PODL_DO_SYSTEM_S] = (
        (dfn[QUERY_HEAT_DISTANCE] < params[ODLEGLOSC_OD_SIECI])
        & ~dfn[PODL_DO_GAZ_I_SYSTEM_GS]
        & (dfn[POW_UZYTKOWA_OGRZEWANA] > params[M2_MIN_DO_SIECI])
    )
    dfn[POZA_PODL_DO_SIECI_GAZ_I_CIEP_N] = (
        ~dfn[PODL_DO_GAZ_I_SYSTEM_GS]
        & ~dfn[TYLKO_PODL_DO_GAZU_G]
        & ~dfn[TYLKO_PODL_DO_SYSTEM_S]
    )

    return dfn
