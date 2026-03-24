from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from app.models.enums import EventType


class EventBase(BaseModel):
    match_id: int
    team_id: int
    player_id: int
    event_type: EventType
    minute: Optional[int] = None
    description: Optional[str] = None


class EventCreate(EventBase):
    pass


class EventUpdate(BaseModel):
    team_id: Optional[int] = None
    player_id: Optional[int] = None
    event_type: Optional[EventType] = None
    minute: Optional[int] = None
    description: Optional[str] = None


class EventOut(EventBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
