"""init

Revision ID: a29a01a06c72
Revises: 
Create Date: 2021-12-15 14:00:51.253462

"""
import geoalchemy2
import sqlalchemy as sa
from alembic import op
from config import settings

# revision identifiers, used by Alembic.
revision = "a29a01a06c72"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.execute(f"CREATE SCHEMA {settings.DB_STAGING_SCHEMA}")
    op.create_table(
        "kiutlayer",
        sa.Column("id", sa.SmallInteger(), nullable=False),
        sa.Column("name", sa.String(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "region",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(), nullable=True),
        sa.Column("teryt", sa.String(), nullable=True),
        sa.Column("created_utc", sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "egib",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("region_id", sa.Integer(), nullable=True),
        sa.Column("source_id", sa.String(), nullable=True),
        sa.Column("type", sa.String(), nullable=True),
        sa.Column(
            "geom",
            geoalchemy2.types.Geometry(
                geometry_type="MULTIPOLYGON",
                srid=settings.DB_SRID,
                spatial_index=False,
                from_text="ST_GeomFromEWKT",
                name="geometry",
            ),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(["region_id"], ["region.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "idx_egib_geom", "egib", ["geom"], unique=False, postgresql_using="gist"
    )
    op.create_table(
        "map",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("layer", sa.SmallInteger(), nullable=True),
        sa.Column(
            "geom",
            geoalchemy2.types.Geometry(
                geometry_type="POLYGON",
                srid=settings.DB_SRID,
                spatial_index=False,
                from_text="ST_GeomFromEWKT",
                name="geometry",
            ),
            nullable=True,
        ),
        sa.Column("image", sa.LargeBinary(), nullable=True),
        sa.Column("url", sa.String(), nullable=True),
        sa.Column("region_id", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["layer"], ["kiutlayer.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["region_id"], ["region.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "idx_map_geom", "map", ["geom"], unique=False, postgresql_using="gist"
    )
    op.create_table(
        "tile",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("map_id", sa.Integer(), nullable=True),
        sa.Column(
            "geom",
            geoalchemy2.types.Geometry(
                geometry_type="POLYGON",
                srid=settings.DB_SRID,
                spatial_index=False,
                from_text="ST_GeomFromEWKT",
                name="geometry",
            ),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(["map_id"], ["map.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "idx_tile_geom", "tile", ["geom"], unique=False, postgresql_using="gist"
    )
    op.create_index(op.f("ix_tile_map_id"), "tile", ["map_id"], unique=False)
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_index(op.f("ix_tile_map_id"), table_name="tile")
    op.drop_index("idx_tile_geom", table_name="tile", postgresql_using="gist")
    op.drop_table("tile")
    op.drop_index("idx_map_geom", table_name="map", postgresql_using="gist")
    op.drop_table("map")
    op.drop_index("idx_egib_geom", table_name="egib", postgresql_using="gist")
    op.drop_table("egib")
    op.drop_table("region")
    op.drop_table("kiutlayer")
    op.execute(f"DROP SCHEMA {settings.DB_STAGING_SCHEMA} CASCADE")
    # ### end Alembic commands ###
