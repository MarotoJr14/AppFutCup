"""unique match field+datetime per tournament

Revision ID: 5a1c8d4f2b90
Revises: 3b2a7f4c1e2d
Create Date: 2026-05-11

"""

from typing import Sequence, Union

from alembic import op


revision: str = "5a1c8d4f2b90"
down_revision: Union[str, None] = "3b2a7f4c1e2d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    dialect = bind.dialect.name

    if dialect == "sqlite":
        with op.batch_alter_table("matches") as batch:
            batch.create_unique_constraint(
                "uq_match_field_datetime",
                ["tournament_id", "field", "datetime"],
            )
        return

    op.create_unique_constraint(
        "uq_match_field_datetime",
        "matches",
        ["tournament_id", "field", "datetime"],
    )


def downgrade() -> None:
    bind = op.get_bind()
    dialect = bind.dialect.name

    if dialect == "sqlite":
        with op.batch_alter_table("matches") as batch:
            batch.drop_constraint("uq_match_field_datetime", type_="unique")
        return

    op.drop_constraint("uq_match_field_datetime", "matches", type_="unique")

