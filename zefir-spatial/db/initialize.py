import logging
from lib2to3.pytree import Base

from sqlalchemy.orm import Session

from config import setup_logging
from db.base_class import Base  # noqa
from db.session import SessionLocal
from feeder.kiut.layers import AllowedLayerNames
from feeder.teryt_codes.import_data import import_terc_codes
from models.kiut_layers import KiutLayer
from models.terc import Terc
from utils.crud import get_kiut_layername_to_id_dict


def add_type_if_not_exists(db: Session, model: Base, init_types: set):
    types = db.query(model.name).all()
    types_set = set(type[0] for type in types)
    to_add = init_types.difference(types_set)
    objects = [model(name=name) for name in to_add]
    db.bulk_save_objects(objects)
    db.commit()


def _add_kiut_layers(db: Session):
    layers_in_db = get_kiut_layername_to_id_dict(db)
    for id_, layer in enumerate(AllowedLayerNames, 1):
        layername = layer.value
        if layername not in layers_in_db:
            obj = KiutLayer(id=id_, name=layername)
            db.add(obj)
    db.commit()


def _add_terc_codes(db: Session):
    if not db.query(Terc).first():
        import_terc_codes(db)


def init(db) -> None:
    print("Creating initial data")
    _add_kiut_layers(db)
    _add_terc_codes(db)
    print("Initial data created")


def main() -> None:
    with SessionLocal() as db:
        init(db)


if __name__ == "__main__":
    main()
