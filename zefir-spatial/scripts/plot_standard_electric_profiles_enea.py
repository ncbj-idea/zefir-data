# skip checking certs
import ssl

ssl._create_default_https_context = ssl._create_unverified_context

# data process part
import pandas as pd
import plotly.graph_objects as go
import numpy as np

MONTHS_NUM = 12
url = "https://www.operator.enea.pl/operator/dla-firmy/iriesd/profile_standardowe_do-iriesd_na-2019_1.xlsx?t=1653559823"

rows = np.r_[0, 7:14, 35:42, 63:70, 91:98, 126:133, 154:161, 182:189, 217:224, 245:252, 280:287, 308:315, 336:343]

with pd.ExcelFile(url) as reader:
    df = pd.read_excel(
        url, sheet_name="G12", skiprows=lambda x: x not in rows, usecols="A:Z",
    )

fig = go.Figure()
for month_num in range(1, MONTHS_NUM+1):
    df_temp = df.iloc[0:7, :]
    df_melted = (df_temp.melt(id_vars=["Data", "Dzień"], var_name="hour", value_name="val")
                 .sort_values(["Data", 'hour'])
                 .reset_index(drop=True)
                 )
    fig.add_trace(
        go.Scatter(
            x=(
                df_melted["Dzień"],
                df_melted["hour"],
            ),
            y=df_melted["val"],
            mode="lines",
            name=str(month_num)
        )
    )

    df = df.iloc[7:, :].reset_index(drop=True)

fig.show()

