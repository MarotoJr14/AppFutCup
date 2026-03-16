from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_roles
from app.models.lineup import Lineup
from app.models.match import Match
from app.models.team import Team
from app.models.player import Player
from app.models.user import User
from app.schemas.lineup import LineupCreate, LineupUpdate, LineupResponse

router = APIRouter(prefix="/lineups", tags=["lineups"])

@router.get("/", response_model=List[LineupResponse])
def list_lineups(
    match_id: int | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    query = db.query(Lineup)

    if match_id:
        query = query.filter(Lineup.match_id == match_id)

    return query.all()

@router.get("/{lineup_id}", response_model=LineupResponse)
def get_lineup(
    lineup_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    lineup = db.query(Lineup).filter(Lineup.id == lineup_id).first()

    if not lineup:
        raise HTTPException(status_code=404, detail="Lineup not found")

    return lineup

@router.post("/", response_model=LineupResponse)
def create_lineup(
    payload: LineupCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin", "org")),
):
    match = db.query(Match).filter(Match.id == payload.match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    team = db.query(Team).filter(Team.id == payload.team_id).first()
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")

    player = db.query(Player).filter(Player.id == payload.player_id).first()
    if not player:
        raise HTTPException(status_code=404, detail="Player not found")

    # Validar que el team juega ese match
    if payload.team_id not in [match.home_team_id, match.away_team_id]:
        raise HTTPException(
            status_code=400,
            detail="Team is not part of this match",
        )

    # (mínimo viable) Evitar duplicado
    existing = (
        db.query(Lineup)
        .filter(
            Lineup.match_id == payload.match_id,
            Lineup.player_id == payload.player_id,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=400,
            detail="Player already in lineup for this match",
        )

    lineup = Lineup(**payload.model_dump())

    db.add(lineup)
    db.commit()
    db.refresh(lineup)

    return lineup

@router.put("/{lineup_id}", response_model=LineupResponse)
def update_lineup(
    lineup_id: int,
    payload: LineupUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin", "org")),
):
    lineup = db.query(Lineup).filter(Lineup.id == lineup_id).first()

    if not lineup:
        raise HTTPException(status_code=404, detail="Lineup not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(lineup, field, value)

    db.commit()
    db.refresh(lineup)

    return lineup

@router.delete("/{lineup_id}")
def delete_lineup(
    lineup_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin")),
):
    lineup = db.query(Lineup).filter(Lineup.id == lineup_id).first()

    if not lineup:
        raise HTTPException(status_code=404, detail="Lineup not found")

    db.delete(lineup)
    db.commit()

    return {"message": "Lineup deleted successfully"}
