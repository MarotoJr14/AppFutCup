from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_roles
from app.models.team import Team
from app.models.user import User
from app.models.tournament import Tournament
from app.schemas.team import TeamCreate, TeamUpdate, TeamResponse
from app.services.team_service import TeamService

router = APIRouter(prefix="/teams", tags=["teams"])

team_service = TeamService()

@router.get("/{team_id}", response_model=TeamResponse)
def get_team(
    team_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        return team_service.get_team(db, team_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/", response_model=TeamResponse)
def create_team(
    payload: TeamCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin", "org")),
):
    try:
        return team_service.create_team(
            db,
            payload.name,
            payload.group,
            payload.kit_color,
            payload.tournament_id,
            payload.logo_url,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/{team_id}", response_model=TeamResponse)
def update_team(
    team_id: int,
    payload: TeamUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin", "org")),
):
    try:
        return team_service.update_team(
            db,
            team_id,
            payload.name,
            payload.group,
            payload.kit_color,
            payload.logo_url,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{team_id}")
def delete_team(
    team_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin")),
):
    try:
        team_service.delete_team(db, team_id)
        return {"message": "Team deleted successfully"}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

