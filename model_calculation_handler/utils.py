import os

import pandas as pd


class DataframePrefix:
    jednorodzinny_kostka = pd.DataFrame(
        {
            "Nazewnictwo dla ZEFIR": [
                "Klasa F",
                "Klasa E",
                "Klasa D ",
                "Klasa Dz",
                "Klasa C",
                "Klasa A",
                "Klasa Cm",
                "Klasa Bz",
                "Klasa Azm",
            ],
            "Klasa energetyczna (skala termomodernizacji)": [
                "Klasa F (180<EU<240)",
                "Klasa E (120<EU<180)",
                "Klasa E (120<EU<180)",
                "Klasa D (90<EU<120)",
                "Klasa C (60<EU<90)",
                "Klasa A (30<EU<60)",
                "Klasa B (30<EU<60)",
                "Klasa C (60<EU<90)",
                "Klasa Az (30<EU<60)",
            ],
            "Rodzaj budynku": [
                "Wariant 1a",
                "Wariant 1b",
                "Wariant 2a",
                "Wariant 2b",
                "Wariant 3",
                "Wariant 6m",
                "Wariant 4m",
                "Wariant 5z",
                "Wariant 6mz",
            ],
            "Powierzchnia użytkowa [m2]": [
                113.38,
                113.38,
                113.38,
                113.38,
                113.38,
                113.38,
                113.38,
                113.38,
                113.38,
            ],
        }
    )
    jednorodzinny_z_poddaszem = pd.DataFrame(
        {
            "Nazewnictwo dla ZEFIR": [
                "Klasa F",
                "Klasa E",
                "Klasa D ",
                "Klasa Dz",
                "Klasa C",
                "Klasa B",
                "Klasa A",
                "Klasa Cm",
                "Klasa Bz",
                "Klasa Azm",
            ],
            "Klasa energetyczna (skala termomodernizacji)": [
                "Klasa F (180<EU<240)",
                "Klasa E (120<EU<180)",
                "Klasa E (120<EU<180)",
                "Klasa D (90<EU<120)",
                "Klasa C (60<EU<90)",
                "Klasa B (30<EU<60)",
                "Klasa A (30<EU<60)",
                "Klasa Cm",
                "Klasa Bz",
                "Klasa Az",
            ],
            "Rodzaj budynku": [
                "Wariant 1a",
                "Wariant 1b",
                "Wariant 2a",
                "Wariant 2b",
                "Wariant 3",
                "Wariant 5",
                "Wariant 6",
                "Wariant 4m",
                "Wariant 5z",
                "Wariant 6z",
            ],
            "Powierzchnia użytkowa [m2]": [
                78.5,
                78.5,
                78.5,
                78.5,
                78.5,
                78.5,
                78.5,
                78.5,
                78.5,
                78.5,
            ],
        }
    )
    wielorodzinny = pd.DataFrame(
        {
            "Nazewnictwo dla ZEFIR": [
                "Klasa F",
                "Klasa E",
                "Klasa D ",
                "Klasa Dz",
                "Klasa C",
                "Klasa B",
                "Klasa A",
                "Klasa Cm",
                "Klasa Bz",
                "Klasa Azm",
            ],
            "Klasa energetyczna (skala termomodernizacji)": [
                "Klasa F (180<EU<240)",
                "Klasa E (120<EU<180)",
                "Klasa E (120<EU<180)",
                "Klasa E (120<EU<180)",
                "Klasa D (90<EU<120)",
                "Klasa C (60<EU<90)",
                "Klasa C (60<EU<90)",
                "Klasa C (60<EU<90)",
                "Klasa C (60<EU<90)",
                "Klasa C (60<EU<90)",
            ],
            "Rodzaj budynku": [
                "Wariant 1a",
                "Wariant 1b",
                "Wariant 2a",
                "Wariant 2b",
                "Wariant 3",
                "Wariant 5",
                "Wariant 6",
                "Wariant 4m",
                "Wariant 5z",
                "Wariant 6z",
            ],
            "Powierzchnia użytkowa [m2]": [
                752.09,
                752.09,
                752.09,
                752.09,
                752.09,
                752.09,
                752.09,
                752.09,
                752.09,
                752.09,
            ],
        }
    )
    kamienica = pd.DataFrame(
        {
            "Nazewnictwo dla ZEFIR": [
                "Klasa F",
                "Klasa E",
                "Klasa D ",
                "Klasa Dz",
                "Klasa C",
                "Klasa Czm",
                "Klasa Zz",
                "Klasa Zzm",
            ],
            "Klasa energetyczna (skala termomodernizacji)": [
                "Klasa G (EU>240)",
                "Klasa F (180<EU<240)",
                "Klasa E (120<EU<180)",
                "Klasa E (120<EU<180)",
                "Klasa C (60<EU<90)",
                "Klasa C (60<EU<90)",
                "Klasa D (90<EU<120)",
                "Klasa B (30<EU<60)",
            ],
            "Rodzaj budynku": [
                "Wariant 1a",
                "Wariant 1b",
                "Wariant 2a",
                "Wariant 2b",
                "Wariant 3",
                "Wariant 4m",
                "Wariant 5z",
                "Wariant 6mz",
            ],
            "Powierzchnia użytkowa [m2]": [
                2480.7,
                2480.7,
                2480.7,
                2480.7,
                2480.7,
                2480.7,
                2480.7,
                2480.7,
            ],
        }
    )
    produkcyjny = pd.DataFrame(
        {
            "Nazewnictwo dla ZEFIR": [
                "Klasa EF",
                "Klasa Dw",
                "Klasa D ",
                "Klasa C",
                "Klasa B",
                "Klasa A",
                "Klasa Cm",
            ],
            "Klasa energetyczna (skala termomodernizacji)": [
                "Klasa F (180<EU<240)",
                "Klasa E (120<EU<180)",
                "Klasa E (120<EU<180)",
                "Klasa C (60<EU<90)",
                "Klasa B (30<EU<60)",
                "Klasa D (90<EU<120)",
                "Klasa C (60<EU<90)",

            ],
            "Rodzaj budynku": [
                "Wariant 1a",
                "Wariant 2graw",
                "Wariant 2mech",
                "Wariant 3",
                "Wariant 3m",
                "Wariant 4",
                "Wariant 4m",
            ],
            "Powierzchnia użytkowa [m2]": [
                1002.2,
                1002.2,
                1002.2,
                1002.2,
                1002.2,
                1002.2,
                1002.2,
            ],
        }
    )
    szkola = pd.DataFrame(
        {
            "Nazewnictwo dla ZEFIR": [
                "Klasa E",
                "Klasa C",
                "Klasa B",
                "Klasa Bc",
                "Klasa Ac",
                "Brak",
                "Brak",
                "Brak",
            ],
            "Klasa energetyczna (skala termomodernizacji)": [
                "Klasa E (120<EU<180)",
                "Klasa E (120<EU<180)",
                "Klasa E (120<EU<180)",
                "Klasa D (90<EU<120)",
                "Klasa C (60<EU<90)",
                "Klasa D (90<EU<120)",
                "Klasa B (30<EU<90)",
                "Klasa B (30<EU<90)",
            ],
            "Rodzaj budynku": [
                "Stan istniejący",
                "Wariant 1",
                "Wariant 2",
                "Wariant 3",
                "Wariant 4",
                "Wariant 5",
                "Wariant 6",
                "Wariant 7",
            ],
            "Powierzchnia użytkowa [m2]": [
                3676.8,
                3676.8,
                3676.8,
                3676.8,
                3676.8,
                3676.8,
                3676.8,
                3676.8,
            ],
        }
    )
    biuro = pd.DataFrame(
        {
            "Nazewnictwo dla ZEFIR": [
                "Klasa D",
                "Klasa C",
                "Klasa B",
                "Klasa Bc",
                "Klasa Ac",
                "Klasa Bz",
                "Klasa Bzc",
                "Klasa Azc",
            ],
            "Klasa energetyczna (skala termomodernizacji)": [
                "Klasa D (90<EU<120)",
                "Klasa D (90<EU<120)",
                "Klasa B (30<EU<60)",
                "Klasa C (60<EU<90)",
                "Klasa B (30<EU<60)",
                "Klasa B (30<EU<60)",
                "Klasa C (60<EU<90)",
                "Klasa B (30<EU<60)",
            ],
            "Rodzaj budynku": [
                "Wariant 1b",
                "Wariant 2b",
                "Wariant 5",
                "Wariant 5a",
                "Wariant 6m",
                "Wariant 5z",
                "Wariant 5az",
                "Wariant 6mz",
            ],
            "Powierzchnia użytkowa [m2]": [
                7129.75,
                7129.75,
                7129.75,
                7129.75,
                7129.75,
                7129.75,
                7129.75,
                7129.75,
            ],
        }
    )

    @staticmethod
    def get_df(name: str) -> pd.DataFrame:
        translate_dict = dict(
            jednorodzinny_kostka=DataframePrefix.jednorodzinny_kostka,
            jednorodzinny_z_poddaszem=DataframePrefix.jednorodzinny_z_poddaszem,
            wielorodzinny=DataframePrefix.wielorodzinny,
            kamienica=DataframePrefix.kamienica,
            produkcyjny=DataframePrefix.produkcyjny,
            szkola=DataframePrefix.szkola,
            biuro=DataframePrefix.biuro,
        )
        result = translate_dict.get(name, None)
        if result is not None:
            return result
        raise ValueError(f"Given name: {name} is not part of Datastructure")


class DHW:
    @staticmethod
    def get_series_by_name(root_path: str, name: str) -> list[float]:
        translate_dict = dict(
            jednorodzinny_kostka="1_Jednorodzinny kostka_DHW.xlsx",
            jednorodzinny_z_poddaszem="3_Jednorodzinny z poddaszem_DHW.xlsx",
            wielorodzinny="4_Wielorodzinny_DHW.xlsx",
            kamienica="5_Kamienica_DHW.xlsx",
            produkcyjny="6_Produkcyjny_DHW.xlsx",
            szkola="7_Szkola_DHW.xlsx",
            biuro="8_Biuro_DHW.xlsx",
        )
        file_name = translate_dict.get(name, None)
        if not file_name:
            raise ValueError(f"Given name: {name} not in data structure")
        df = pd.read_excel(os.path.join(root_path, file_name), index_col=False)
        return df["DHW"].to_list()
