from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_roles
from app.models.player_team import PlayerTeam
from app.models.player import Player
from app.models.team import Team
from app.models.user import User
from app.schemas.player_team import PlayerTeamCreate, PlayerTeamUpdate, PlayerTeamResponse
from app.services.player_team_service import PlayerTeamService

router = APIRouter(prefix="/player-teams", tags=["player-teams"])

player_team_service = PlayerTeamService()

@router.get("/", response_model=List[PlayerTeamResponse])
def list_player_teams(
    team_id: int | None = None,
    player_id: int | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return player_team_service.list_player_teams(
        db,
        team_id,
        player_id,
    )


@router.get("/{relation_id}", response_model=PlayerTeamResponse)
def get_player_team(
    relation_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    relation = db.query(PlayerTeam).filter(PlayerTeam.id == relation_id).first()

    if not relation:
        raise HTTPException(status_code=404, detail="Relation not found")

    return relation

@router.post("/", response_model=PlayerTeamResponse)
def create_player_team(
    payload: PlayerTeamCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin", "org")),
):
    # Validar que exista el jugador
    player = db.query(Player).filter(Player.id == payload.player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")

    # Validar que exista el equipo
    team = db.query(Team).filter(Team.id == payload.team_id).first()
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")

    # Evitar duplicados
    existing = (
        db.query(PlayerTeam)
        .filter(
            PlayerTeam.player_id == payload.player_id,
            PlayerTeam.team_id == payload.team_id,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Player already assigned to this team",
        )

    relation = PlayerTeam(**payload.model_dump())

    db.add(relation)
    db.commit()
    db.refresh(relation)

    return relation

@router.put("/{relation_id}", response_model=PlayerTeamResponse)
def update_player_team(
    relation_id: int,
    payload: PlayerTeamUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin", "org")),
):
    relation = db.query(PlayerTeam).filter(PlayerTeam.id == relation_id).first()

    if not relation:
        raise HTTPException(status_code=404, detail="Relation not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(relation, field, value)

    db.commit()
    db.refresh(relation)

    return relation

@router.delete("/{player_team_id}")
def remove_player(
    player_team_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin")),
):
    try:
        player_team_service.remove_player_from_team(
            db,
            player_team_id,
        )
        return {"message": "Player removed from team"}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

