from config import settings
from db.base_class import Base
from geoalchemy2 import Geometry
from sqlalchemy import Boolean, Column, ForeignKey, Index, Integer, String
from sqlalchemy.dialects import postgresql
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.declarative import declared_attr
from sqlalchemy_json import mutable_json_type


class Bdot10k(Base):
    id = Column(Integer, primary_key=True)
    import_id = Column(Integer, ForeignKey("import_metadata.id", ondelete="CASCADE"))
    identyfikator = Column(String)
    funkcja_ogolna = Column(String)
    funkcja_szczegolowa = Column(postgresql.ARRAY(String))
    liczba_kondygnacji = Column(Integer)
    kst = Column(String)
    czy_zabytek = Column(Boolean)
    other = Column(mutable_json_type(dbtype=JSONB, nested=True))  # type: ignore
    geom = Column(Geometry("Multipolygon", spatial_index=False, srid=settings.DB_SRID))  # type: ignore # noqa

    @declared_attr
    def __table_args__(cls):
        return (
            Index(
                "idx_{}_geom".format(cls.__tablename__),
                "geom",
                postgresql_using="gist",
            ),
        )
