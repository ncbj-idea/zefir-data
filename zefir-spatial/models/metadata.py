import datetime

from db.base_class import Base
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy_json import mutable_json_type


class ImportMetadata(Base):
    __tablename__ = "import_metadata"  # type: ignore
    id = Column(Integer, primary_key=True)
    table_name = Column(String)
    import_datetime_utc = Column(DateTime, default=datetime.datetime.utcnow)
    meta = Column(mutable_json_type(dbtype=JSONB, nested=True))  # type: ignore


class MappingImportToTerc(Base):
    __tablename__ = "import_to_terc"  # type: ignore
    import_id = Column(
        Integer,
        ForeignKey(f"{ImportMetadata.__tablename__}.id", ondelete="CASCADE"),
        primary_key=True,
    )
    terc = Column(String, primary_key=True)
