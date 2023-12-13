import pandas as pd
from db.session import engine


def read_from_csv(path: str):
    return pd.read_csv(path)


def read_from_db(terc: str):
    stm = "SELECT * FROM get_gis_data_for_given_terc(%(terc)s)"
    return pd.read_sql(stm, engine, params={"terc": terc})
