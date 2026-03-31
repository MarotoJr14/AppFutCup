from datetime import datetime as dt
from typing import Optional
from pydantic import BaseModel
from app.models.enums import MatchRound, MatchStatus


class MatchBase(BaseModel):
    tournament_id: int
    round: MatchRound
    status: MatchStatus = MatchStatus.Pending
    team_home_id: Optional[int] = None
    team_away_id: Optional[int] = None
    goals_home: Optional[int] = None
    goals_away: Optional[int] = None
    pen_home: Optional[int] = None
    pen_away: Optional[int] = None
    datetime: Optional[dt] = None
    field: Optional[str] = None


class MatchCreate(BaseModel):
    tournament_id: int
    round: MatchRound
    status: MatchStatus = MatchStatus.Pending


class MatchUpdate(BaseModel):
    team_home_id: Optional[int] = None
    team_away_id: Optional[int] = None
    goals_home: Optional[int] = None
    goals_away: Optional[int] = None
    pen_home: Optional[int] = None
    pen_away: Optional[int] = None
    datetime: Optional[dt] = None
    field: Optional[str] = None
    status: Optional[MatchStatus] = None
    round: Optional[MatchRound] = None


class MatchOut(MatchBase):
    id: int
    created_at: dt
    updated_at: Optional[dt] = None

    model_config = {"from_attributes": True}
