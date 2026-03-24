from datetime import datetime
from sqlalchemy import Integer, ForeignKey, DateTime, Index, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base


class PlayerTeam(Base):
    __tablename__ = "player_teams"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id"), nullable=False)
    team_id: Mapped[int] = mapped_column(Integer, ForeignKey("teams.id"), nullable=False)
    number: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=True, onupdate=func.now())

    __table_args__ = (
        UniqueConstraint("team_id", "number", name="uq_team_number"),
        UniqueConstraint("team_id", "player_id", name="uq_team_player"),
        Index("idx_player_teams_player_id", "player_id"),
    )
