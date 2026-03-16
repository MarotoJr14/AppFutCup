from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_roles
from app.models.match import Match
from app.models.team import Team
from app.models.tournament import Tournament
from app.models.user import User
from app.schemas.match import MatchCreate, MatchUpdate, MatchResponse
from app.services.match_service import MatchService

router = APIRouter(prefix="/matches", tags=["matches"])

match_service = MatchService()

@router.get("/", response_model=List[MatchResponse])
def list_matches(
    tournament_id: int | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return match_service.list_matches(db, tournament_id)


@router.get("/{match_id}", response_model=MatchResponse)
def get_match(
    match_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        return match_service.get_match(db, match_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/", response_model=MatchResponse)
def create_match(
    payload: MatchCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin", "org")),
):
    try:
        return match_service.create_match(
            db,
            payload.home_team_id,
            payload.away_team_id,
            payload.tournament_id,
            payload.date,
            payload.location,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


# @router.patch("/{match_id}/score", response_model=MatchResponse)
# def update_score(
#     match_id: int,
#     payload: MatchScoreUpdate,
#     db: Session = Depends(get_db),
#     user: User = Depends(require_roles("admin", "org")),
# ):
#     try:
#         return match_service.update_score(
#             db,
#             match_id,
#             payload.home_score,
#             payload.away_score,
#         )
#     except ValueError as e:
#         raise HTTPException(status_code=404, detail=str(e))


@router.delete("/{match_id}")
def delete_match(
    match_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin")),
):
    try:
        match_service.delete_match(db, match_id)
        return {"message": "Match deleted successfully"}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
