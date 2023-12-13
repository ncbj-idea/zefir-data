from db.base_class import Base
from sqlalchemy import Column, String


class Terc(Base):
    kod = Column(String(7), primary_key=True)
    woj = Column(String(2))
    pow = Column(String(2))
    gmi = Column(String(2))
    rodz = Column(String(1))
    nazwa = Column(String)
    nazwa_dod = Column(String)
