from pydantic import BaseModel
from typing import Optional


class EventBase(BaseModel):
    match_id: int
    player_id: int
    minute: int
    type: str


class EventCreate(EventBase):
    pass


class EventUpdate(BaseModel):
    minute: Optional[int] = None
    type: Optional[str] = None


class EventResponse(EventBase):
    id: int

    class Config:
        from_attributes = True
