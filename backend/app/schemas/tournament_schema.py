from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class TournamentBase(BaseModel):
    name: str
    place: str
    date_ini: datetime
    date_end: datetime
    is_active: bool = True


class TournamentCreate(TournamentBase):
    pass


class TournamentUpdate(BaseModel):
    name: Optional[str] = None
    place: Optional[str] = None
    date_ini: Optional[datetime] = None
    date_end: Optional[datetime] = None
    is_active: Optional[bool] = None


class TournamentOut(TournamentBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
