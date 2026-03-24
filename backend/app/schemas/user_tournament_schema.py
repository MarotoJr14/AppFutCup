from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class UserTournamentBase(BaseModel):
    user_id: int
    tournament_id: int


class UserTournamentCreate(UserTournamentBase):
    pass


class UserTournamentOut(UserTournamentBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
