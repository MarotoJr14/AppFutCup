from datetime import datetime
from sqlalchemy import Integer, ForeignKey, DateTime, Enum, Index, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
from app.models.enums import LineupRole


class Lineup(Base):
    __tablename__ = "lineups"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    match_id: Mapped[int] = mapped_column(Integer, ForeignKey("matches.id"), nullable=False)
    team_id: Mapped[int] = mapped_column(Integer, ForeignKey("teams.id"), nullable=False)
    player_id: Mapped[int] = mapped_column(Integer, ForeignKey("players.id"), nullable=False)
    role: Mapped[LineupRole] = mapped_column(Enum(LineupRole), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=True, onupdate=func.now())

    __table_args__ = (
        UniqueConstraint("match_id", "team_id", "player_id", name="uq_lineup_match_team_player"),
        Index("idx_lineups_match_id", "match_id"),
        Index("idx_lineups_match_team_id", "match_id", "team_id"),
        Index("idx_lineups_player_id", "player_id"),
    )
