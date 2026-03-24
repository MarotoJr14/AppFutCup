from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_org, require_admin
from app.services.player_team_service import PlayerTeamService
from app.schemas.player_team_schema import PlayerTeamCreate, PlayerTeamUpdate, PlayerTeamOut
from app.models.user import User

router = APIRouter(prefix="/player-teams", tags=["Player Teams"])


class RegisterPlayerRequest(BaseModel):
    dni: str
    name: str | None = None
    team_id: int
    number: int


@router.get("/", response_model=list[PlayerTeamOut])
def get_all(team_id: int | None = None, skip: int = 0, limit: int = 100,
            db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    svc = PlayerTeamService(db)
    if team_id:
        return svc.get_by_team(team_id)
    return svc.get_all(skip, limit)


@router.get("/{pt_id}", response_model=PlayerTeamOut)
def get_by_id(pt_id: int, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    return PlayerTeamService(db).get_by_id(pt_id)


@router.post("/", response_model=PlayerTeamOut, status_code=201)
def add_player_to_team(data: PlayerTeamCreate, db: Session = Depends(get_db), _: User = Depends(require_org)):
    return PlayerTeamService(db).add_player_to_team(data)


@router.post("/register", response_model=PlayerTeamOut, status_code=201)
def register_player(data: RegisterPlayerRequest, db: Session = Depends(get_db), _: User = Depends(require_org)):
    """Search player by DNI; create if not found, then add to team."""
    return PlayerTeamService(db).register_player(data.dni, data.name, data.team_id, data.number)


@router.patch("/{pt_id}", response_model=PlayerTeamOut)
def update(pt_id: int, data: PlayerTeamUpdate, db: Session = Depends(get_db), _: User = Depends(require_org)):
    return PlayerTeamService(db).update(pt_id, data)


@router.delete("/{pt_id}", status_code=204)
def delete(pt_id: int, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    PlayerTeamService(db).delete(pt_id)
