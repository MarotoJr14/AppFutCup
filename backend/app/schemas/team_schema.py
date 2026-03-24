from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class TeamBase(BaseModel):
    name: str
    group: str
    tournament_id: int
    kit_color: str
    logo_url: Optional[str] = None


class TeamCreate(TeamBase):
    pass


class TeamUpdate(BaseModel):
    name: Optional[str] = None
    group: Optional[str] = None
    kit_color: Optional[str] = None
    logo_url: Optional[str] = None


class TeamOut(TeamBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
