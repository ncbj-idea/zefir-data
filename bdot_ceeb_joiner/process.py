import copy
import re
from typing import Tuple, Union

import numpy as np
import pandas as pd
import recordlinkage
from tqdm import tqdm

from bdot_ceeb_joiner.config import Config

tqdm.pandas()


def process(
    config: Config, ceeb_join_bdot: bool = True
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    bdot_df = pd.read_excel(config.bdot_path)
    ceeb_df = pd.read_excel(config.ceeb_path)
    # bdot_df = bdot_raw.loc[bdot_raw["addr_distance"] == 0.0]
    if config.zabytki_path:
        zabytki_df = pd.read_excel(config.zabytki_path)
        bdot_df = bdot_df.merge(
            zabytki_df, on=["ulica", "numer_porzadkowy"], how="left"
        )
    ceeb_df["ceeb_key"] = (
        ceeb_df["Ulica"].str.lower() + " " + ceeb_df["Numer"].str.lower()
    )
    bdot_df["bdot_key"] = (
        bdot_df["ulica"].str.lower() + " " + bdot_df["numer_porzadkowy"].str.lower()
    )
    # bdot_df = bdot_df.drop_duplicates(subset="bdot_key")

    matches = compare_addr(ceeb_df, bdot_df, ceeb_join_bdot)
    matches_dict = dict(matches.index)
    concat, only = [], []
    if ceeb_join_bdot:
        ceeb_df.progress_apply(
            ceeb_bdot_joining_process,
            matches=matches,
            matches_dict=matches_dict,
            bdot_df=bdot_df,
            ceeb_bdot_concat=concat,
            only_ceeb=only,
            axis=1,
        )
    else:
        bdot_df.progress_apply(
            bdot_ceeb_joining_process,
            matches=matches,
            matches_dict=matches_dict,
            ceeb_df=ceeb_df,
            bdot_ceeb_concat=concat,
            only_bdot=only,
            axis=1,
        )
    joined = pd.DataFrame(concat)
    joined = _add_is_valid_column(joined)
    joined = _add_numer_porzadkowy_error_column(joined)
    joined = _add_do_weryfikacji_column(joined)
    non_joined = pd.DataFrame(only)

    return joined, non_joined


def ceeb_bdot_joining_process(
    ceeb_data: pd.Series,
    matches: pd.DataFrame,
    matches_dict: dict[int, int],
    bdot_df: pd.DataFrame,
    ceeb_bdot_concat: list[pd.Series],
    only_ceeb: list[pd.Series],
) -> None:
    if ceeb_data.name in matches_dict:
        bdot_idx = matches_dict[ceeb_data.name]  # noqa
        bdot = bdot_df.loc[bdot_idx]
        comb = pd.concat([ceeb_data, bdot], axis=0)
        comb["ulica_error"] = matches.loc[(ceeb_data.name, bdot_idx)].values[0]
        ceeb_bdot_concat.append(copy.copy(comb))
    else:
        only_ceeb.append(copy.copy(ceeb_data))


def bdot_ceeb_joining_process(
    bdot_data: pd.Series,
    matches: pd.DataFrame,
    matches_dict: dict[int, int],
    ceeb_df: pd.DataFrame,
    bdot_ceeb_concat: list[pd.Series],
    only_bdot: list[pd.Series],
) -> None:
    if bdot_data.name in matches_dict:
        ceeb_idx = matches_dict[bdot_data.name]  # noqa
        ceeb = ceeb_df.loc[ceeb_idx]
        comb = pd.concat([bdot_data, ceeb], axis=0)
        comb["ulica_error"] = matches.loc[(bdot_data.name, ceeb_idx)].values[0]
        bdot_ceeb_concat.append(copy.copy(comb))
    else:
        only_bdot.append(copy.copy(bdot_data))


def compare_addr(
    ceeb_df: pd.DataFrame, bdot_df: pd.DataFrame, ceeb_join_bdot: bool
) -> pd.DataFrame:
    if ceeb_join_bdot:
        indexer = recordlinkage.Index()
        indexer.block(left_on="ceeb_key", right_on="bdot_key")
        buildings = indexer.index(ceeb_df, bdot_df)
        compare = recordlinkage.Compare()
        compare.string("ceeb_key", "bdot_key", method="qgram", threshold=0.85)
        matches = compare.compute(buildings, ceeb_df, bdot_df)
    else:
        indexer = recordlinkage.Index()
        indexer.block(left_on="bdot_key", right_on="ceeb_key")
        buildings = indexer.index(bdot_df, ceeb_df)
        compare = recordlinkage.Compare()
        compare.string("bdot_key", "ceeb_key", method="qgram", threshold=0.85)
        matches = compare.compute(buildings, bdot_df, ceeb_df)
    return matches


def _add_is_valid_column(df: pd.DataFrame) -> pd.DataFrame:
    """Column is_valid has been set by following constaint:
    if the Euclidean distance between "numer_porzadkowy" and "Numer" is less thah 0.1,
    then column "is_valid" set to True, otherwise False"""

    def _count_distance(row: pd.Series) -> pd.Series:
        number = int(re.sub("\D", "", str(row["Numer"])))
        number_porzadkowy = int(re.sub("\D", "", str(row["numer_porzadkowy"])))
        dist = np.linalg.norm(number_porzadkowy - number)
        return dist < 0.1

    df["is_valid"] = df.apply(_count_distance, axis=1)
    return df


def _add_numer_porzadkowy_error_column(df: pd.DataFrame) -> pd.DataFrame:
    """Column "numer_porzadkowy_error" has been set by following constaint:
    if the Euclidean distance between "numer_porzadkowy" and "Numer" is less thah 0.1,
    then column "numer_porzadkowy_error" set to 1, otherwise: 1-dist"""

    def _count_distance(row: pd.Series) -> Union[int, float]:
        number = int(re.sub("\D", "", str(row["Numer"])))
        number_porzadkowy = int(re.sub("\D", "", str(row["numer_porzadkowy"])))
        dist = np.linalg.norm(number_porzadkowy - number)
        if dist < 0.1:
            return 1
        else:
            return 1 - dist

    df["numer_porzadkowy_error"] = df.apply(_count_distance, axis=1)
    return df


def _add_do_weryfikacji_column(df: pd.DataFrame) -> pd.DataFrame:
    """Column "do_weryfikacji" has been set by following constaint:
    for rows where "ulica_error" is less than 0.7: if ("is_valid" is False)
    OR ("is_valid" is True AND 0.5 < ulica_error < 1) then set to True, otherwise False
    """
    mask = df["ulica_error"] < 0.7
    df.loc[mask, "do_weryfikacji"] = np.where(
        (~df.loc[mask, "is_valid"])
        | (df.loc[mask, "is_valid"] & (df.loc[mask, "ulica_error"].between(0.5, 1))),
        True,
        False,
    )
    df.loc[~mask, "do_weryfikacji"] = False
    return df
