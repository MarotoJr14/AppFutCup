from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_admin
from app.services.tournament_service import TournamentService
from app.schemas.tournament_schema import TournamentCreate, TournamentUpdate, TournamentOut
from app.models.user import User

router = APIRouter(prefix="/tournaments", tags=["Tournaments"])


@router.get("/", response_model=list[TournamentOut])
def get_all(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    return TournamentService(db).get_all(skip, limit)


@router.get("/{tournament_id}", response_model=TournamentOut)
def get_by_id(tournament_id: int, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    return TournamentService(db).get_by_id(tournament_id)


@router.post("/", response_model=TournamentOut, status_code=201)
def create(data: TournamentCreate, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return TournamentService(db).create(data)


@router.patch("/{tournament_id}", response_model=TournamentOut)
def update(tournament_id: int, data: TournamentUpdate, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return TournamentService(db).update(tournament_id, data)


@router.delete("/{tournament_id}", status_code=204)
def delete(tournament_id: int, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    TournamentService(db).delete(tournament_id)
