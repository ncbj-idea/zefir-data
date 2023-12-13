import xml.etree.ElementTree as ET
from pathlib import Path

from config import ROOT_DIR
from models.terc import Terc
from sqlalchemy.orm.session import Session

PATH = Path(ROOT_DIR / "data" / "teryt" / "TERC_Urzedowy_2021-12-23.xml")


def import_terc_codes(db: Session):
    """
    https://eteryt.stat.gov.pl/eTeryt/rejestr_teryt/udostepnianie_danych/baza_teryt/uzytkownicy_indywidualni/pobieranie/pliki_pelne.aspx?contrast=default
    """
    tree = ET.parse(PATH)
    root = tree.getroot()
    mappings = []
    for row in root.find("catalog"):
        elements = {el.tag: el.text for el in row}
        teryt = "".join(
            elements[code] if elements[code] is not None else ""
            for code in ["WOJ", "POW", "GMI", "RODZ"]
        )
        mappings.append(
            {
                "kod": teryt,
                "woj": elements["WOJ"],
                "pow": elements["POW"],
                "gmi": elements["GMI"],
                "rodz": elements["RODZ"],
                "nazwa": elements["NAZWA"],
                "nazwa_dod": elements["NAZWA_DOD"],
            }
        )
    db.bulk_insert_mappings(Terc, mappings)
    db.commit()


if __name__ == "__main__":
    from db.base import Base
    from db.session import SessionLocal

    db = SessionLocal()
    Base.metadata.create_all(db.bind)
    import_terc_codes(db)
