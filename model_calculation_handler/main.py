import glob
import os

import pandas as pd

from KAPE_parser.DHW_series import KapeExcelHandler
from KAPE_parser.utils import DataframePrefix

root_output_path = "path_to_root_output_path"
dhw_path = "path_to_dhw_path"
root_dir_path = "path_to_root_dir_path"
name = "name_of_building"


list_of_cities = ["Ustka", "Poznan", "Suwalki", "Olsztyn", "Elblag", "Bielsko.Biala"]

for miasto in list_of_cities:
    df_dict = {}
    for file_path in glob.glob(os.path.join(root_dir_path, f"**/*{miasto}*/*.csv")):
        category = file_path.split("/")[-3]
        output_path = os.path.join(root_output_path, miasto)
        ts_output_path = os.path.join(output_path, category)
        if not os.path.exists(ts_output_path):
            os.makedirs(ts_output_path)
        dhw_file = pd.read_excel(dhw_path, index_col=False)
        output_df = pd.read_csv(file_path, index_col=False)
        df_water, df_electr, sum_water, dhw_sum = KapeExcelHandler(
            dhw_file, output_df
        ).create_series_and_sums_rows()
        df_water.to_csv(os.path.join(ts_output_path, "water.csv"), index=False)
        df_electr.to_csv(os.path.join(ts_output_path, "electric.csv"), index=False)
        df_dict[category] = {
            "Użytkowa (co i wentylacja)": sum_water,
            "Użytkowa (cwu)": dhw_sum,
        }

    df_row = DataframePrefix.get_df(name)
    df_row = df_row.sort_values("Rodzaj budynku")
    df = pd.DataFrame(df_dict).T
    df = df.sort_index().reset_index().drop("index", axis=1)
    df_res = pd.concat([df_row, df], axis=1)
    df_res["Użytkowa (co i wentylacja) przez powierzchnie"] = (
        df_res["Użytkowa (co i wentylacja)"] / df_res["Powierzchnia użytkowa [m2]"]
    )
    df_res["Użytkowa (cwu) przez powierzchnie"] = (
        df_res["Użytkowa (cwu)"] / df_res["Powierzchnia użytkowa [m2]"]
    )
    df_res.to_excel(
        os.path.join(output_path, f"zestawienie_dla_{miasto}.xlsx"), index=False
    )
