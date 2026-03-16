from pydantic import BaseModel
from typing import Optional


class LineupBase(BaseModel):
    match_id: int
    team_id: int
    player_id: int
    is_starting: bool = True


class LineupCreate(LineupBase):
    pass


class LineupUpdate(BaseModel):
    is_starting: Optional[bool] = None


class LineupResponse(LineupBase):
    id: int

    class Config:
        from_attributes = True
