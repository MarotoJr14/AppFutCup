from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from pydantic import BaseModel
from app.db.deps import get_db
from app.api.v1.deps import get_current_user
from app.models.user import User
from app.models.event import Event
from app.models.lineup import Lineup
from app.models.player_team import PlayerTeam
from app.models.match import Match
from app.models.enums import EventType, LineupRole

router = APIRouter(prefix="/player-stats", tags=["Player Stats"])


class PlayerStats(BaseModel):
    player_id: int
    player_name: str
    team_name: str
    number: int
    matches_starter: int
    matches_bench: int
    goals: int
    goals_per_match: float
    yellow_cards: int
    double_yellows: int
    red_cards: int


@router.get("/{player_id}", response_model=PlayerStats)
def get_player_stats(
    player_id: int,
    tournament_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    from app.models.player import Player
    from app.models.team import Team
    from fastapi import HTTPException

    # Basic player + team info
    pt = (
        db.query(PlayerTeam, Player, Team)
        .join(Player, Player.id == PlayerTeam.player_id)
        .join(Team, Team.id == PlayerTeam.team_id)
        .filter(PlayerTeam.player_id == player_id, Team.tournament_id == tournament_id)
        .first()
    )
    if not pt:
        raise HTTPException(status_code=404, detail="Jugador no encontrado en este torneo")
    player_team, player, team = pt

    # Matches as starter
    starter = (
        db.query(func.count(Lineup.id))
        .join(Match, Match.id == Lineup.match_id)
        .filter(Lineup.player_id == player_id, Lineup.role == LineupRole.Starter, Match.tournament_id == tournament_id)
        .scalar()
    )
    # Matches as bench
    bench = (
        db.query(func.count(Lineup.id))
        .join(Match, Match.id == Lineup.match_id)
        .filter(Lineup.player_id == player_id, Lineup.role == LineupRole.Bench, Match.tournament_id == tournament_id)
        .scalar()
    )

    def count_event(etype):
        return (
            db.query(func.count(Event.id))
            .join(Match, Match.id == Event.match_id)
            .filter(Event.player_id == player_id, Event.event_type == etype, Match.tournament_id == tournament_id)
            .scalar()
        )

    goals = count_event(EventType.Goal)
    total_matches = (starter or 0) + (bench or 0)

    return PlayerStats(
        player_id=player.id,
        player_name=player.name,
        team_name=team.name,
        number=player_team.number,
        matches_starter=starter or 0,
        matches_bench=bench or 0,
        goals=goals or 0,
        goals_per_match=round(goals / total_matches, 2) if total_matches else 0.0,
        yellow_cards=count_event(EventType.Yellow) or 0,
        double_yellows=count_event(EventType.YellowX2) or 0,
        red_cards=count_event(EventType.Red) or 0,
    )
