import logging
from typing import List

from db.session import SessionLocal
from sqlalchemy import Column, Table, column, func, select, text
from sqlalchemy.sql.functions import Function

logger = logging.getLogger(__name__)


def bulild_json_column(
    jsonized_columns: List[Column],
) -> Function:
    # jsonized = (column(colname) for colname in jsonized_columns)
    tmp_alias = "d"
    json_ = func.json_strip_nulls(
        func.row_to_json(
            select(column(tmp_alias))
            .select_from(select(*jsonized_columns).alias(tmp_alias))
            .scalar_subquery()
        )
    )
    return json_


def build_insert(columns: List[Column], source_table: Table, destination_table: Table):
    sel = select(columns).select_from(source_table)
    ins = destination_table.insert().from_select(sel.subquery().columns, sel)
    return ins


def create_procedure(stm):
    with SessionLocal() as db:
        db.execute(stm)
        db.commit()


def call_procedure(procedure_name, *parameters):
    with SessionLocal() as db:
        binded_params = {f"param{i}": value for i, value in enumerate(parameters)}
        placeholders = ", ".join(f":{k}" for k in binded_params.keys())
        sanitized_procedure_name = str(column(procedure_name))
        stm = f"CALL {sanitized_procedure_name}({placeholders})"
        db.execute(text(stm), binded_params)
        logger.debug("Calling: `%s` with params: %s", stm, binded_params)
        db.commit()
