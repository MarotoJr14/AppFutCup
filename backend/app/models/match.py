from datetime import datetime
from typing import Optional
from sqlalchemy import Integer, String, ForeignKey, DateTime, Enum, Index, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
from app.models.enums import MatchRound, MatchStatus


class Match(Base):
    __tablename__ = "matches"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    team_home_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("teams.id"), nullable=True)
    team_away_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("teams.id"), nullable=True)
    goals_home: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    goals_away: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    pen_home: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    pen_away: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    datetime: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    field: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    tournament_id: Mapped[int] = mapped_column(Integer, ForeignKey("tournaments.id"), nullable=False)
    round: Mapped[MatchRound] = mapped_column(Enum(MatchRound), nullable=False)
    status: Mapped[MatchStatus] = mapped_column(Enum(MatchStatus), nullable=False, default=MatchStatus.Pending)
    created_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, nullable=True, onupdate=func.now())
    
    __table_args__ = (
        Index("idx_matches_teams", "team_home_id", "team_away_id"),
        Index("idx_matches_datetime", "datetime"),
        Index("idx_matches_round", "round"),
        Index("idx_matches_status", "status"),
        Index("idx_matches_field", "field"),
        Index("idx_matches_tournament_id", "tournament_id"),
    )
