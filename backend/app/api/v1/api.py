from fastapi import APIRouter

from app.api.v1.routes import (
    auth,
    users,
    teams,
    players,
    player_teams,
    matches,
    events,
    lineups,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(teams.router, prefix="/teams", tags=["teams"])
api_router.include_router(players.router, prefix="/players", tags=["players"])
api_router.include_router(player_teams.router, prefix="/player-teams", tags=["player-teams"])
api_router.include_router(matches.router, prefix="/matches", tags=["matches"])
api_router.include_router(events.router, prefix="/events", tags=["events"])
api_router.include_router(lineups.router, prefix="/lineups", tags=["lineups"])
