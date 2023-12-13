from db.base_class import Base
from sqlalchemy import Column, SmallInteger, String


class KiutLayer(Base):
    id = Column(SmallInteger, primary_key=True)
    name = Column(String)
