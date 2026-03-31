"""add penalties status and penalty scores

Revision ID: 3b2a7f4c1e2d
Revises: 0998c86903cb
Create Date: 2026-03-30

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "3b2a7f4c1e2d"
down_revision: Union[str, None] = "0998c86903cb"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    dialect = bind.dialect.name

    if dialect == "postgresql":
        # Extend enums
        op.execute("ALTER TYPE matchstatus ADD VALUE IF NOT EXISTS 'Penalties'")
        op.execute("ALTER TYPE eventtype ADD VALUE IF NOT EXISTS 'PenaltyScored'")
        op.execute("ALTER TYPE eventtype ADD VALUE IF NOT EXISTS 'PenaltyMissed'")

        # Add columns
        op.add_column("matches", sa.Column("pen_home", sa.Integer(), nullable=True))
        op.add_column("matches", sa.Column("pen_away", sa.Integer(), nullable=True))
        return

    # SQLite / other dialects: recreate CHECK constraints via batch alter
    matchstatus_old = sa.Enum("Pending", "Playing", "Finished", name="matchstatus")
    matchstatus_new = sa.Enum("Pending", "Playing", "Penalties", "Finished", name="matchstatus")

    eventtype_old = sa.Enum("Goal", "Owngoal", "Yellow", "YellowX2", "Red", name="eventtype")
    eventtype_new = sa.Enum(
        "Goal",
        "Owngoal",
        "Yellow",
        "YellowX2",
        "Red",
        "PenaltyScored",
        "PenaltyMissed",
        name="eventtype",
    )

    with op.batch_alter_table("matches") as batch:
        batch.add_column(sa.Column("pen_home", sa.Integer(), nullable=True))
        batch.add_column(sa.Column("pen_away", sa.Integer(), nullable=True))
        batch.alter_column("status", existing_type=matchstatus_old, type_=matchstatus_new, nullable=False)

    with op.batch_alter_table("events") as batch:
        batch.alter_column("event_type", existing_type=eventtype_old, type_=eventtype_new, nullable=False)


def downgrade() -> None:
    # NOTE: PostgreSQL enums can't safely remove values; we only drop the new columns.
    bind = op.get_bind()
    dialect = bind.dialect.name

    if dialect == "postgresql":
        op.drop_column("matches", "pen_away")
        op.drop_column("matches", "pen_home")
        return

    matchstatus_old = sa.Enum("Pending", "Playing", "Penalties", "Finished", name="matchstatus")
    matchstatus_new = sa.Enum("Pending", "Playing", "Finished", name="matchstatus")

    eventtype_old = sa.Enum(
        "Goal",
        "Owngoal",
        "Yellow",
        "YellowX2",
        "Red",
        "PenaltyScored",
        "PenaltyMissed",
        name="eventtype",
    )
    eventtype_new = sa.Enum("Goal", "Owngoal", "Yellow", "YellowX2", "Red", name="eventtype")

    with op.batch_alter_table("matches") as batch:
        batch.drop_column("pen_away")
        batch.drop_column("pen_home")
        batch.alter_column("status", existing_type=matchstatus_old, type_=matchstatus_new, nullable=False)

    with op.batch_alter_table("events") as batch:
        batch.alter_column("event_type", existing_type=eventtype_old, type_=eventtype_new, nullable=False)

