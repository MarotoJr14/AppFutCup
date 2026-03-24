from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class PlayerBase(BaseModel):
    name: str
    dni: str


class PlayerCreate(PlayerBase):
    pass


class PlayerUpdate(BaseModel):
    name: Optional[str] = None
    dni: Optional[str] = None


class PlayerOut(PlayerBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
