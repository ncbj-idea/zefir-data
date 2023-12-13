# skip checking certs
import ssl
import pandas as pd
import numpy as np
from pathlib import Path

ssl._create_default_https_context = ssl._create_unverified_context

# data process part

#rows = [0, 7, 35, 63, 91, 126, 154, 182, 217, 245, 280, 308, 336]
# , skiprows=lambda x: x not in rows
url = "https://www.operator.enea.pl/operator/dla-firmy/iriesd/profile_standardowe_do-iriesd_na-2019_1.xlsx?t=1653559823"

tariffs_dict = pd.read_excel(
    url, sheet_name=None, usecols="A:Z"
)

demand_profiles = {}
for tariff_name, tariff_df in tariffs_dict.items():
    try:
        tariff_df_melted = tariff_df.melt(
            id_vars=["Data", "Dzień"], var_name="hour", value_name="val"
        ).dropna(subset="val")

        tariff_df_melted_sorted = tariff_df_melted.sort_values(["Data", "hour"]).reset_index(drop=True)
        assert tariff_df_melted_sorted.shape == (8760, 4)

        demand_profile = tariff_df_melted_sorted["val"]
        sum_demand = demand_profile.sum()
        normalized_demand_profile = demand_profile / sum_demand
        assert np.isclose(normalized_demand_profile.sum(), 1)
        demand_profiles[tariff_name] = normalized_demand_profile
    except Exception as e:
        print(f"Error for key {tariff_name}:", e)


dir = Path("demand_profiles")
dir.mkdir(exist_ok=True)
for tariff_name, demand_profile in demand_profiles.items():
    path = dir / f"{tariff_name}_enea.csv"
    demand_profile.to_csv(path, index=False, header=False)
