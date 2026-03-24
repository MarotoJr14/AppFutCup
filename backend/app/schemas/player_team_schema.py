from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class PlayerTeamBase(BaseModel):
    player_id: int
    team_id: int
    number: int


class PlayerTeamCreate(PlayerTeamBase):
    pass


class PlayerTeamUpdate(BaseModel):
    number: Optional[int] = None


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
