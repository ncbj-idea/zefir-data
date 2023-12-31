"""Alter maps and tiles table to add debug info

Revision ID: d8fe99050004
Revises: 71ed79e063bc
Create Date: 2022-01-31 13:30:20.267025

"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "d8fe99050004"
down_revision = "71ed79e063bc"
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table(
        "column_mapper",
        sa.Column("table_name", sa.String(), nullable=False),
        sa.Column("fr", sa.String(), nullable=False),
        sa.Column("to", sa.String(), nullable=True),
        sa.PrimaryKeyConstraint("table_name", "fr"),
    )
    op.create_table(
        "import_metadata",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("table_name", sa.String(), nullable=True),
        sa.Column("import_datetime_utc", sa.DateTime(), nullable=True),
        sa.Column("meta", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "kst_mapper",
        sa.Column("fr", sa.String(), nullable=False),
        sa.Column("to", sa.String(), nullable=True),
        sa.PrimaryKeyConstraint("fr"),
    )
    op.create_table(
        "import_to_terc",
        sa.Column("import_id", sa.Integer(), nullable=False),
        sa.Column("terc", sa.String(), nullable=False),
        sa.ForeignKeyConstraint(
            ["import_id"], ["import_metadata.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("import_id", "terc"),
    )
    op.add_column("egib", sa.Column("import_id", sa.Integer(), nullable=True))
    op.add_column("egib", sa.Column("identyfikator", sa.String(), nullable=True))
    op.add_column("egib", sa.Column("kst", sa.String(), nullable=True))
    op.add_column(
        "egib",
        sa.Column("other", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
    )
    op.drop_constraint("fk_egib_region_id_region", "egib", type_="foreignkey")
    op.create_foreign_key(
        "egib_import_id_fkey",
        "egib",
        "import_metadata",
        ["import_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.drop_column("egib", "source_id")
    op.drop_column("egib", "type")
    op.drop_column("egib", "region_id")
    op.add_column("map", sa.Column("terc", sa.String(length=7), nullable=True))
    op.add_column("map", sa.Column("import_id", sa.Integer(), nullable=True))
    op.drop_constraint("fk_map_region_id_region", "map", type_="foreignkey")
    op.create_foreign_key(
        "map_import_id_fkey",
        "map",
        "import_metadata",
        ["import_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.drop_column("map", "region_id")
    op.add_column("tile", sa.Column("layer", sa.SmallInteger(), nullable=True))
    op.add_column("tile", sa.Column("image", sa.LargeBinary(), nullable=True))
    op.add_column(
        "tile",
        sa.Column("debug", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
    )
    op.create_foreign_key(
        "tile_layer_fkey", "tile", "kiutlayer", ["layer"], ["id"], ondelete="CASCADE"
    )
    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_constraint("tile_layer_fkey", "tile", type_="foreignkey")
    op.drop_column("tile", "debug")
    op.drop_column("tile", "image")
    op.drop_column("tile", "layer")
    op.add_column(
        "map", sa.Column("region_id", sa.INTEGER(), autoincrement=False, nullable=True)
    )
    op.drop_constraint("map_import_id_fkey", "map", type_="foreignkey")
    op.create_foreign_key(
        "map_region_id_fkey", "map", "region", ["region_id"], ["id"], ondelete="CASCADE"
    )
    op.drop_column("map", "import_id")
    op.drop_column("map", "terc")
    op.add_column(
        "egib", sa.Column("region_id", sa.INTEGER(), autoincrement=False, nullable=True)
    )
    op.add_column(
        "egib", sa.Column("type", sa.VARCHAR(), autoincrement=False, nullable=True)
    )
    op.add_column(
        "egib", sa.Column("source_id", sa.VARCHAR(), autoincrement=False, nullable=True)
    )
    op.drop_constraint("egib_import_id_fkey", "egib", type_="foreignkey")
    op.create_foreign_key(
        "egib_region_id_fkey",
        "egib",
        "region",
        ["region_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.drop_column("egib", "other")
    op.drop_column("egib", "kst")
    op.drop_column("egib", "identyfikator")
    op.drop_column("egib", "import_id")
    op.drop_table("import_to_terc")
    op.drop_table("kst_mapper")
    op.drop_table("import_metadata")
    op.drop_table("column_mapper")
    # ### end Alembic commands ###
