from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class PlayerTeamBase(BaseModel):
    player_id: int
    team_id: int
    number: int = Field(ge=1, le=99)


class PlayerTeamCreate(PlayerTeamBase):
    pass


class PlayerTeamUpdate(BaseModel):
    number: Optional[int] = Field(default=None, ge=1, le=99)


class PlayerTeamOut(PlayerTeamBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class PlayerWithNumber(BaseModel):
    player_id: int
    player_name: str
    number: int
    team_id: int

    model_config = {"from_attributes": True}
