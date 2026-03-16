from pydantic import BaseModel
from typing import Optional


class PlayerTeamBase(BaseModel):
    player_id: int
    team_id: int
    number: int | None = None
    position: str | None = None


class PlayerTeamCreate(PlayerTeamBase):
    pass


class PlayerTeamUpdate(BaseModel):
    number: int | None = None
    position: str | None = None


class PlayerTeamResponse(PlayerTeamBase):
    id: int

    class Config:
        from_attributes = True
