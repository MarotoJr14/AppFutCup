from sqlalchemy import Integer, DateTime, ForeignKey, Enum, Index, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base
from datetime import datetime
from .enums import LineupRole

class Lineup(Base):
    __tablename__ = "lineups"

    id: Mapped[int] = mapped_column(primary_key=True)
    match_id: Mapped[int] = mapped_column(ForeignKey("matches.id"), nullable=False)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False)
    player_id: Mapped[int] = mapped_column(ForeignKey("players.id"), nullable=False)
    role: Mapped[LineupRole] = mapped_column(Enum(LineupRole), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=True
    )
    
    __table_args__ = (
        UniqueConstraint("match_id", "team_id", "player_id", name="uq_lineup_match_team_player"),
        Index("idx_lineups_match_id", "match_id"),
        Index("idx_lineups_match_team_id", "match_id", "team_id"),
        Index("idx_lineups_player_id", "player_id"),
    )
