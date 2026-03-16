from pydantic import BaseModel
from typing import Optional


class MatchBase(BaseModel):
    tournament_id: int
    home_team_id: int
    away_team_id: int
    home_score: Optional[int] = 0
    away_score: Optional[int] = 0


class MatchCreate(MatchBase):
    pass


class MatchUpdate(BaseModel):
    home_score: Optional[int] = None
    away_score: Optional[int] = None


class MatchResponse(MatchBase):
    id: int

    class Config:
        from_attributes = True
