"""create bdot10k table

Revision ID: 6b9c32255ded
Revises: 942a4ae58270
Create Date: 2022-02-03 13:34:34.945847

"""
import geoalchemy2 as ga
import sqlalchemy as sa
from alembic import op
from config import settings
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "6b9c32255ded"
down_revision = "942a4ae58270"
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table(
        "bdot10k",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("import_id", sa.Integer(), nullable=True),
        sa.Column("identyfikator", sa.String(), nullable=True),
        sa.Column("funkcja_ogolna", sa.String(), nullable=True),
        sa.Column("funkcja_szczegolowa", postgresql.ARRAY(sa.String()), nullable=True),
        sa.Column("liczba_kondygnacji", sa.Integer(), nullable=True),
        sa.Column("kst", sa.String(), nullable=True),
        sa.Column("czy_zabytek", sa.Boolean(), nullable=True),
        sa.Column("other", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column(
            "geom",
            ga.types.Geometry(
                geometry_type="MULTIPOLYGON",
                srid=settings.DB_SRID,
                spatial_index=False,
                from_text="ST_GeomFromEWKT",
                name="geometry",
            ),
            nullable=True,
        ),
        sa.ForeignKeyConstraint(
            ["import_id"],
            ["import_metadata.id"],
            name=op.f("fk_bdot10k_import_id_import_metadata"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_bdot10k")),
    )
    op.create_index(
        "idx_bdot10k_geom", "bdot10k", ["geom"], unique=False, postgresql_using="gist"
    )
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_index("idx_bdot10k_geom", table_name="bdot10k", postgresql_using="gist")
    op.drop_table("bdot10k")
    # ### end Alembic commands ###
