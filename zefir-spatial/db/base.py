# Import all the models, so that Base has them before being
# imported by Alembic
from models.address_point import AddressPoint  # noqa
from models.bdot import Bdot10k  # noqa
from models.egib import Egib  # noqa
from models.kiut_layers import KiutLayer  # noqa
from models.map import Map  # noqa
from models.metadata import ImportMetadata, MappingImportToTerc  # noqa
from models.names_mapper import ColumnMapper, KstMapper  # noqa
from models.prg import AdministrativeBoundary  # noqa
from models.region import Region  # noqa
from models.terc import Terc  # noqa
from models.tile import Tile  # noqa

from db.base_class import Base  # noqa
