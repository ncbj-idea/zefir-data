import datetime

from db.base_class import Base
from sqlalchemy import Column, DateTime, Integer, String


class Region(Base):
    id = Column(Integer, primary_key=True)
    name = Column(String)
    teryt = Column(String)
    created_utc = Column(DateTime, default=datetime.datetime.utcnow)
