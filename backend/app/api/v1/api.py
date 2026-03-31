from fastapi import APIRouter
from app.api.v1.routes import (
    auth, users, tournaments, user_tournaments,
    teams, players, player_teams, matches,
    lineups, events, player_stats, audit_logs,
)

api_router = APIRouter(prefix="/api/v1", redirect_slashes=False)

api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(tournaments.router)
api_router.include_router(user_tournaments.router)
api_router.include_router(teams.router)
api_router.include_router(players.router)
api_router.include_router(player_teams.router)
api_router.include_router(matches.router)
api_router.include_router(lineups.router)
api_router.include_router(events.router)
api_router.include_router(player_stats.router)
api_router.include_router(audit_logs.router)
