from datetime import datetime, date
import random

from app.db.session import SessionLocal
from app.models import User, Tournament, Team, Player, PlayerTeam, Match, Event, Lineup, AuditLog
from app.models.enums import UserRole, MatchRound, MatchStatus, EntityType, ActionType, LineupRole, EventType

# -------------------------------------
# helpers
# -------------------------------------

def commit(session):
    try:
        session.commit()
    except Exception:
        session.rollback()
        raise

# -------------------------------------
# seed
# -------------------------------------

def run():
    db = SessionLocal()

    # ---------------- USERS ----------------
    users = [
        User(
            username="admin",
            email="admin@pro2fp.es",
            password_hash="hashed_admin",
            role=UserRole.admin,
        ),
        User(
            username="org",
            email="org@pro2fp.es",
            password_hash="hashed_org",
            role=UserRole.org,
        ),
        User(
            username="user",
            email="user@pro2fp.es",
            password_hash="hashed_user",
            role=UserRole.user,
        ),
    ]
    db.add_all(users)
    commit(db)

    # ---------------- TOURNAMENTS ----------------
    tournament = Tournament(
        name="FutCup 2025",
        year="2025",
    )
    db.add(tournament)
    commit(db)

    # ---------------- TEAMS ----------------
    teams = []
    for i in range(1, 9):
        team = Team(
            name=f"Team {i}",
            group="1º PRO2FP" if i % 2 == 0 else "2º PRO2FP",
            tournament_id=tournament.id,
            kit_color=f"Color {i}",
        )
        teams.append(team)

    db.add_all(teams)
    commit(db)

    # ---------------- PLAYERS ----------------
    players = []
    for i in range(1, 81):  # 80 jugadores
        player = Player(
            name=f"Jugador {i}",
            # DNI/NIE de ejemplo válido: X + 7 dígitos + letra
            dni=f"X{i:07d}A",
        )
        players.append(player)

    db.add_all(players)
    commit(db)

    # ---------------- PLAYER ↔ TEAM (N:N) ----------------
    shuffled_players = players[:]
    random.shuffle(shuffled_players)
    
    idx = 0
    for team in teams:  # 8 equipos por edición
        squad = shuffled_players[idx:idx + 10]
        idx += 10

        for number, player in enumerate(squad, start=1):
            db.add(
                PlayerTeam(
                    player_id=player.id,
                    team_id=team.id,
                    number=number,
                )
            )

    commit(db)

    # ---------------- MATCHES ----------------
    rounds = ["quarterfinal", "semifinal", "final"]
    matches = []
    for r in rounds:
        for i in range(4 if r == "quarterfinal" else 2 if r == "semifinal" else 1):
            t1, t2 = random.sample(teams, 2)
            matches.append(
                Match(
                    team_home_id=t1.id if r == "quarterfinal" else None,
                    team_away_id=t2.id if r == "quarterfinal" else None,
                    tournament_id=tournament.id,
                    round=MatchRound(r),
                    status=MatchStatus.pending,
                )
            )
    
    db.add_all(matches)
    commit(db)
    
    # ---------------- LINEUPS ----------------
    lineups = []
    
    for match in matches:
        home_team_players = db.query(PlayerTeam).filter_by(team_id=match.team_home_id).all()
        away_team_players = db.query(PlayerTeam).filter_by(team_id=match.team_away_id).all()

        starterCount = 0
        
        for player in home_team_players:
            lineups.append(
                Lineup(
                    player_id=player.player_id,
                    match_id=match.id,
                    team_id=player.team_id,
                    role = LineupRole.starter if starterCount < 5 else LineupRole.bench
                )
            )
            starterCount += 1
            if starterCount == 10:
                starterCount = 0

        starterCount = 0
        
        for player in away_team_players:
            lineups.append(
                Lineup(
                    player_id=player.player_id,
                    match_id=match.id,
                    team_id=player.team_id,
                    role = LineupRole.starter if starterCount < 5 else LineupRole.bench
                )
            )
            starterCount += 1
            if starterCount == 10:
                starterCount = 0

    db.add_all(lineups)
    commit(db)

    # ---------------- EVENTS ----------------
    # events = []
    # for match in matches:
    #     for i in range(random.randint(5, 15)):  # Entre 5 y 15 eventos por partido
    #         player_team = random.choice(db.query(PlayerTeam).filter(
    #             (PlayerTeam.team_id == match.team_home_id) | (PlayerTeam.team_id == match.team_away_id)
    #         ).all())
    #         events.append(
    #             Event(
    #                 match_id=match.id,
    #                 team_id=player_team.team_id,
    #                 player_id=player_team.player_id,
    #                 event_type=EventType.goal,
    #                 minute=random.randint(1, 26),
    #             )
    #         )

    # db.add_all(events)
    # commit(db)

    # ---------------- AUDIT LOGS ----------------
    # logs = []
    # for _ in range(30):
    #     logs.append(
    #         AuditLog(
    #             entity=random.choice(["player", "team", "match", "event", "lineup", "user"]),
    #             action=random.choice(["create", "update", "delete"]),
    #             user_id=random.choice(users).id,
    #         )
    #     )

    # db.add_all(logs)
    # commit(db)

    db.close()
    print("✅ Seed completado correctamente")


if __name__ == "__main__":
    run()
