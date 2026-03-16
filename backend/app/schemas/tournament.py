from pydantic import BaseModel
from typing import Optional


class TournamentBase(BaseModel):
    name: str
    year: int


class TournamentCreate(TournamentBase):
    pass


class TournamentUpdate(BaseModel):
    name: Optional[str] = None
    year: Optional[int] = None


class TournamentResponse(TournamentBase):
    id: int

    class Config:
        from_attributes = True
