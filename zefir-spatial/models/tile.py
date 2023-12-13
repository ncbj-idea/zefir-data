from config import settings
from db.base_class import Base
from geoalchemy2 import Geometry
from sqlalchemy import Column, ForeignKey, Index, Integer, LargeBinary, SmallInteger
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.declarative import declared_attr
from sqlalchemy_json import mutable_json_type


class Tile(Base):
    id = Column(Integer, primary_key=True)
    map_id = Column(Integer, ForeignKey("map.id", ondelete="CASCADE"), index=True)
    geom = Column(Geometry("Polygon", spatial_index=False, srid=settings.DB_SRID))  # type: ignore
    layer = Column(SmallInteger, ForeignKey("kiutlayer.id", ondelete="CASCADE"))
    image = Column(LargeBinary)
    debug = Column(mutable_json_type(dbtype=JSONB, nested=True))  # type: ignore

    @declared_attr
    def __table_args__(cls):
        return (
            Index(
                "idx_{}_geom".format(cls.__tablename__),
                "geom",
                postgresql_using="gist",
            ),
        )
