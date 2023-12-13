import json

import geopandas
import pandas as pd

org_path = (
    "/home/kkrolikowski/projects/longtermklastry/parameters/data/zywiec/buildings.json"
)
new_path = "/home/kkrolikowski/projects/longtermklastry/parameters/data/zywiec_kk/buildings.json"

out_path = "buildings_json_zywiec.xlsx"
USE_DB = True
SAVE_TO_FILE = False
#


def get_gdf(path):
    with open(path, "r") as f:
        j = json.load(f)
    df = pd.json_normalize(j)
    gdf = geopandas.GeoDataFrame(
        df,
        geometry=geopandas.points_from_xy(
            df["address.lon"], df["address.lat"], crs="EPSG:4326"
        ),
    )
    return gdf


org_gdf = get_gdf(org_path)


new_gdf = get_gdf(new_path)


if USE_DB:
    from db.session import engine

    org_gdf.to_postgis("org_gdf", engine, schema="tmp", if_exists="replace")
    new_gdf.to_postgis("new_gdf", engine, schema="tmp", if_exists="replace")
    stm = """SELECT *
    FROM tmp.new_gdf AS new_zywiec
         LEFT JOIN LATERAL (
    SELECT o.*,
           St_Distance(o.geometry,  new_zywiec.geometry) AS dist
    FROM tmp.org_gdf AS o
    ORDER BY new_zywiec.geometry <-> o.geometry
    LIMIT 1
    ) AS old_zywiec
                   ON true;"""
    merged_df = pd.read_sql(stm, engine)
    # merged['cmp_address'] = merged_df['address.street']

if SAVE_TO_FILE:
    with pd.ExcelWriter(out_path) as writer:
        org_gdf.to_excel(writer, sheet_name="zywiec_old")
        new_gdf.to_excel(writer, sheet_name="zywiec_new")
        merged_df.to_excel(writer, sheet_name="zywiec_merged")
print(0)
