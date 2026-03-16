from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_roles
from app.models.player import Player
from app.models.player_team import PlayerTeam
from app.models.user import User
from app.schemas.player import PlayerCreate, PlayerUpdate, PlayerResponse
from app.services.player_service import PlayerService

router = APIRouter(prefix="/players", tags=["players"])

player_service = PlayerService()

@router.get("/", response_model=List[PlayerResponse])
def list_players(
    team_id: int | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return player_service.list_players(db, team_id)


@router.get("/{player_id}", response_model=PlayerResponse)
def get_player(
    player_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    try:
        return player_service.get_player(db, player_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/", response_model=PlayerResponse)
def create_player(
    payload: PlayerCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin", "org")),
):
    try:
        return player_service.create_player(
            db,
            payload.name,
            payload.number,
            payload.position,
            payload.team_id,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/{player_id}", response_model=PlayerResponse)
def update_player(
    player_id: int,
    payload: PlayerUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin", "org")),
):
    try:
        return player_service.update_player(
            db,
            player_id,
            payload.name,
            payload.number,
            payload.position,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{player_id}")
def delete_player(
    player_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin")),
):
    try:
        player_service.delete_player(db, player_id)
        return {"message": "Player deleted successfully"}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
