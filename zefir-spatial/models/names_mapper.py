from db.base_class import Base
from sqlalchemy import Column, String


class ColumnMapper(Base):
    __tablename__ = "column_mapper"
    table_name = Column(String, primary_key=True)
    fr = Column(String, primary_key=True)
    to = Column(String)


class KstMapper(Base):
    __tablename__ = "kst_mapper"
    fr = Column(String, primary_key=True)
    to = Column(String)
