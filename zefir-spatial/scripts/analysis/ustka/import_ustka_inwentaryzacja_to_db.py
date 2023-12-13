import numpy as np
import pandas as pd
from db.session import engine

path_inwenaryzajca = "scripts/analysis/ustka/USTKA MIASTO IZC_baza.xlsx"
# https://ncbj.sharepoint.com/:f:/s/IDEA/Ejy8zAjljcpLlSJyqQCgyKgBupK45ySR9SI2DZDZKcZLvQ?e=jZOUtP
raw_inw_df = pd.read_excel(
    path_inwenaryzajca, sheet_name="forms0", header=None, index_col=None
)
columns = (
    (
        raw_inw_df.iloc[0, :].fillna(method="ffill")
        + " "
        + raw_inw_df.iloc[1, :].replace(np.nan, "")
    )
    .str.strip()
    .tolist()
)

inw_df = pd.DataFrame(data=raw_inw_df.iloc[2:].values, columns=columns)
inw_df.to_sql("inwentaryzacja", engine, schema="ustka", if_exists="replace")
