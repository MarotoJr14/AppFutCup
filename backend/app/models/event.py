from sqlalchemy import String, Integer, DateTime, ForeignKey, Enum, Index, func
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base
from datetime import datetime
from .enums import EventType

class Event(Base):
    __tablename__ = "events"

    id: Mapped[int] = mapped_column(primary_key=True)
    match_id: Mapped[int] = mapped_column(ForeignKey("matches.id"), nullable=False)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False)
    player_id: Mapped[int] = mapped_column( ForeignKey("players.id"), nullable=False)
    event_type: Mapped[EventType] = mapped_column(Enum(EventType), nullable=False)
    minute: Mapped[int] = mapped_column(Integer, nullable=True)
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)
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
            Index("idx_events_match_id", "match_id"),
            Index("idx_events_match_player_id", "match_id", "player_id"),
            Index("idx_events_player_id", "player_id"),
            Index("idx_events_event_type", "event_type"),
            Index("idx_events_minute", "minute"),
    )
