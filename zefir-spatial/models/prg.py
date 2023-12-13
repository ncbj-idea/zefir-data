from config import settings
from db.base_class import Base
from geoalchemy2 import Geometry
from sqlalchemy import Column, ForeignKey, Index, Integer, String
from sqlalchemy.ext.declarative import declared_attr


class AdministrativeBoundary(Base):
    __tablename__ = "administrative_boundary"
    terc = Column(String(7), primary_key=True)
    import_id = Column(
        Integer, ForeignKey("import_metadata.id", ondelete="CASCADE"), primary_key=True
    )
    name = Column(String)
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
