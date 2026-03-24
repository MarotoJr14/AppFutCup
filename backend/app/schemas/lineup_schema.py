from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from app.models.enums import LineupRole


class LineupBase(BaseModel):
    match_id: int
    team_id: int
    player_id: int
    role: LineupRole


class LineupCreate(LineupBase):
    pass


class LineupBulkCreate(BaseModel):
    lineups: list[LineupCreate]


class LineupUpdate(BaseModel):
    role: Optional[LineupRole] = None


class LineupOut(LineupBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
