from pydantic import BaseModel
from typing import Optional


class TeamBase(BaseModel):
    name: str
    group: str
    kit_color: str
    tournament_id: int
    logo_url: Optional[str] = None


class TeamCreate(TeamBase):
    pass


class TeamUpdate(BaseModel):
    name: Optional[str] = None
    group: Optional[str] = None
    kit_color: Optional[str] = None
    logo_url: Optional[str] = None


class TeamResponse(TeamBase):
    id: int

    class Config:
        from_attributes = True
