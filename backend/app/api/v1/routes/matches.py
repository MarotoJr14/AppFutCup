from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_org, require_admin
from app.services.match_service import MatchService
from app.schemas.match_schema import MatchCreate, MatchUpdate, MatchOut
from app.models.enums import MatchRound
from app.models.user import User

router = APIRouter(prefix="/matches", tags=["Matches"])


@router.get("/", response_model=list[MatchOut])
def get_all(tournament_id: int | None = None, round: MatchRound | None = None,
            skip: int = 0, limit: int | None = None,
            db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    svc = MatchService(db)
    if tournament_id and round:
        return svc.get_by_tournament_and_round(tournament_id, round)
    if tournament_id:
        return svc.get_by_tournament(tournament_id)
    return svc.get_all(skip, limit)


@router.get("/{match_id}", response_model=MatchOut)
def get_by_id(match_id: int, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    return MatchService(db).get_by_id(match_id)


@router.post("/", response_model=MatchOut, status_code=201)
def create(data: MatchCreate, db: Session = Depends(get_db), current_user: User = Depends(require_org)):
    return MatchService(db).create(data, actor_id=current_user.id)


@router.patch("/{match_id}", response_model=MatchOut)
def update(match_id: int, data: MatchUpdate, db: Session = Depends(get_db), current_user: User = Depends(require_org)):
    return MatchService(db).update(match_id, data, actor_id=current_user.id)


@router.delete("/{match_id}", status_code=204)
def delete(match_id: int, db: Session = Depends(get_db), current_user: User = Depends(require_admin)):
    MatchService(db).delete(match_id, actor_id=current_user.id)
