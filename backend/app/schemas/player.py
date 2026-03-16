from pydantic import BaseModel
from typing import Optional


class PlayerBase(BaseModel):
    name: str
    dni: str


class PlayerCreate(PlayerBase):
    pass


class PlayerUpdate(BaseModel):
    name: Optional[str] = None
    dni: Optional[str] = None


class PlayerResponse(PlayerBase):
    id: int

    class Config:
        from_attributes = True
