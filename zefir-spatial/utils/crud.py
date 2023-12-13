from typing import Any, Dict

from models.kiut_layers import KiutLayer
from models.metadata import ImportMetadata, MappingImportToTerc
from models.names_mapper import ColumnMapper
from sqlalchemy.orm.session import Session


def create_metadata_for_import(db: Session, tablename: str, metadata: Dict[str, Any]):
    obj = ImportMetadata(table_name=tablename, meta=metadata)  # type: ignore
    db.add(obj)
    db.flush()
    return obj


def create_import_to_terc_mapping(db: Session, import_id: int, terc: str):
    obj = MappingImportToTerc(import_id=import_id, terc=terc)
    db.add(obj)
    db.flush()
    return obj


def get_kiut_layer_by_name(db: Session, layer_name: str) -> KiutLayer:
    obj = db.query(KiutLayer).filter(KiutLayer.name == layer_name).one()
    return obj


def get_kiut_layername_to_id_dict(db: Session) -> Dict[str, int]:
    return {obj.name: obj.id for obj in db.query(KiutLayer).all()}
