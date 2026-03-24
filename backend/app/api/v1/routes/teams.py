from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_org, require_admin
from app.services.team_service import TeamService
from app.schemas.team_schema import TeamCreate, TeamUpdate, TeamOut
from app.models.user import User

router = APIRouter(prefix="/teams", tags=["Teams"])


@router.get("/", response_model=list[TeamOut])
def get_all(tournament_id: int | None = None, skip: int = 0, limit: int = 100,
            db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    svc = TeamService(db)
    if tournament_id:
        return svc.get_by_tournament(tournament_id)
    return svc.get_all(skip, limit)


@router.get("/{team_id}", response_model=TeamOut)
def get_by_id(team_id: int, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    return TeamService(db).get_by_id(team_id)


@router.post("/", response_model=TeamOut, status_code=201)
def create(data: TeamCreate, db: Session = Depends(get_db), current_user: User = Depends(require_org)):
    return TeamService(db).create(data, actor_id=current_user.id)


@router.patch("/{team_id}", response_model=TeamOut)
def update(team_id: int, data: TeamUpdate, db: Session = Depends(get_db), current_user: User = Depends(require_org)):
    return TeamService(db).update(team_id, data, actor_id=current_user.id)


@router.delete("/{team_id}", status_code=204)
def delete(team_id: int, db: Session = Depends(get_db), current_user: User = Depends(require_admin)):
    TeamService(db).delete(team_id, actor_id=current_user.id)
