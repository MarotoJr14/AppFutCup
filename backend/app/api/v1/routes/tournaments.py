from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_roles
from app.models.tournament import Tournament
from app.models.user import User
from app.schemas.tournament import TournamentCreate, TournamentUpdate, TournamentResponse
from app.services.tournament_service import TournamentService

router = APIRouter(prefix="/tournaments", tags=["tournaments"])

tournament_service = TournamentService()

@router.get("/", response_model=List[TournamentResponse])
def list_tournaments(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return tournament_service.list_tournaments(db)

@router.get("/{tournament_id}", response_model=TournamentResponse)
def get_tournament(
    tournament_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        return tournament_service.get_tournament(db, tournament_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/", response_model=TournamentResponse)
def create_tournament(
    payload: TournamentCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin")),
):
    try:
        return tournament_service.create_tournament(
            db,
            payload.name,
            payload.year,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/{tournament_id}", response_model=TournamentResponse)
def update_tournament(
    tournament_id: int,
    payload: TournamentUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin")),
):
    try:
        return tournament_service.update_tournament(
            db,
            tournament_id,
            payload.name,
            payload.year,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{tournament_id}")
def delete_tournament(
    tournament_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin")),
):
    try:
        tournament_service.delete_tournament(db, tournament_id)
        return {"message": "Tournament deleted successfully"}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

