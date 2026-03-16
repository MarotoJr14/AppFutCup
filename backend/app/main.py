from fastapi import FastAPI
from app.api.v1.routes import auth, users, tournaments, teams, players, player_teams, matches, events, lineups

app = FastAPI(
    title="FutCup API",
    version="1.0.0"
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(tournaments.router)
app.include_router(teams.router)
app.include_router(players.router)
app.include_router(player_teams.router)
app.include_router(matches.router)
app.include_router(events.router)
app.include_router(lineups.router)