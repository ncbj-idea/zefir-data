import copy

import pandas as pd


class DHWSeriesCreator:
    def __init__(self, dhw_excel: pd.DataFrame) -> None:
        self.dhw_excel = dhw_excel

    def create_series(self) -> pd.Series:
        df = copy.copy(self.dhw_excel)
        suma = df["DHW"].sum()
        df["DHW"] = df["DHW"] / suma
        return df.squeeze()


class KapeExcelHandler:
    def __init__(self, dhw_excel: pd.DataFrame, output_excel: pd.DataFrame) -> None:
        self.dhw_excel = dhw_excel
        self.df = output_excel

    def _create_dhw_data(self) -> tuple[pd.DataFrame, float]:
        df = copy.copy(self.dhw_excel)
        suma = df["DHW"].sum()
        df["DHW"] = df["DHW"] * 3600000
        return df, suma

    def _withdraw_columns(self) -> tuple[pd.DataFrame, pd.DataFrame]:
        df_electr = self.df.loc[:, ["Date/Time", "Electricity:Facility [J](Hourly)"]]
        df_heat = self.df.loc[:, ["Date/Time", "DistrictHeating:Facility [J](Hourly)"]]
        return df_electr, df_heat

    def create_series_and_sums_rows(
        self,
    ) -> tuple[pd.DataFrame, pd.DataFrame, float, float]:
        df_electr, df_heat = self._withdraw_columns()
        df_dhw, dhw_sum = self._create_dhw_data()

        df_electr["Electricity:Facility [J](Hourly)"] = (
            df_electr["Electricity:Facility [J](Hourly)"] / 3600000
        )
        df_electr = df_electr.rename(
            columns={"Electricity:Facility [J](Hourly)": "values"}
        )
        electr_suma = df_electr["values"].sum()
        df_electr["values"] = df_electr["values"] / electr_suma

        df_heat["water"] = (
            df_heat["DistrictHeating:Facility [J](Hourly)"] - df_dhw["DHW"]
        )
        df_heat["water"] = df_heat["water"].apply(lambda x: 0 if x < 0 else x)
        df_heat["water"] = df_heat["water"] / 3600000
        sum_water = df_heat["water"].sum()
        df_water = df_heat.loc[:, ["Date/Time", "water"]]
        df_water["water"] = df_water["water"] / sum_water

        return df_water, df_electr, sum_water, dhw_sum


