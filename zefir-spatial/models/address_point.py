from config import settings
from db.base_class import Base
from geoalchemy2 import Geometry
from sqlalchemy import Column, ForeignKey, Index, Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.declarative import declared_attr
from sqlalchemy_json import mutable_json_type


class AddressPoint(Base):
    __tablename__ = "address_point"
    id = Column(Integer, primary_key=True)
    import_id = Column(Integer, ForeignKey("import_metadata.id", ondelete="CASCADE"))
    miejscowosc = Column(String)
    kod_pocztowy = Column(String(6))
    ulica = Column(String)
    numer_porzadkowy = Column(String)
    geom = Column(Geometry("Point", spatial_index=False, srid=settings.DB_SRID))  # type: ignore # noqa
    other = Column(mutable_json_type(dbtype=JSONB, nested=True))  # type: ignore

    @declared_attr
    def __table_args__(cls):
        return (
            Index(
                "idx_{}_geom".format(cls.__tablename__),
                "geom",
                postgresql_using="gist",
            ),
        )
