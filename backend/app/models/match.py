from sqlalchemy import String, Integer, DateTime, ForeignKey, Enum, Index, func
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base
from datetime import datetime
from .enums import MatchStatus, MatchRound

class Match(Base):
    __tablename__ = "matches"

    id: Mapped[int] = mapped_column(primary_key=True)
    team_home_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=True)
    team_away_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=True)
    goals_home: Mapped[int] = mapped_column(Integer, default=0, nullable=True)
    goals_away: Mapped[int] = mapped_column(Integer, default=0, nullable=True)
    datetime: Mapped[datetime] = mapped_column(DateTime, nullable=True)
    field: Mapped[str | None] = mapped_column(String(100), nullable=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"), nullable=False)
    round: Mapped[MatchRound] = mapped_column(Enum(MatchRound), nullable=False)
    status: Mapped[MatchStatus] = mapped_column(Enum(MatchStatus), default=MatchStatus.pending, nullable=False)
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
        Index("idx_matches_teams", "team_home_id", "team_away_id"),
        Index("idx_matches_datetime", "datetime"),
        Index("idx_matches_round", "round"),
        Index("idx_matches_status", "status"),
        Index("idx_matches_field", "field"),
        Index("idx_matches_tournament_id", "tournament_id"),
    )
