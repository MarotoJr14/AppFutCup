from sqlalchemy.orm import Session
from app.models.match import Match
from app.repositories.match_repository import MatchRepository
from app.repositories.team_repository import TeamRepository
from app.repositories.tournament_repository import TournamentRepository


class MatchService:

    def __init__(self):
        self.match_repo = MatchRepository()
        self.team_repo = TeamRepository()
        self.tournament_repo = TournamentRepository()

    # 🔎 Get
    def get_match(self, db: Session, match_id: int) -> Match:
        match = self.match_repo.get_by_id(db, match_id)
        if not match:
            raise ValueError("Match not found")
        return match

    # 📋 List
    def list_matches(
        self,
        db: Session,
        tournament_id: int | None = None,
    ) -> list[Match]:
        return self.match_repo.list(db, tournament_id)

    # ➕ Create
    def create_match(
        self,
        db: Session,
        home_team_id: int,
        away_team_id: int,
        tournament_id: int,
        date,
        location: str | None = None,
    ) -> Match:

        # 1️⃣ Validar torneo
        tournament = self.tournament_repo.get_by_id(db, tournament_id)
        if not tournament:
            raise ValueError("Tournament not found")

        # 2️⃣ Validar equipos
        home_team = self.team_repo.get_by_id(db, home_team_id)
        away_team = self.team_repo.get_by_id(db, away_team_id)

        if not home_team or not away_team:
            raise ValueError("One or both teams not found")

        # 3️⃣ No pueden ser el mismo equipo
        if home_team_id == away_team_id:
            raise ValueError("A team cannot play against itself")

        # 4️⃣ Ambos equipos deben pertenecer al torneo
        if (
            home_team.tournament_id != tournament_id
            or away_team.tournament_id != tournament_id
        ):
            raise ValueError("Teams must belong to the same tournament")

        match = Match(
            home_team_id=home_team_id,
            away_team_id=away_team_id,
            tournament_id=tournament_id,
            date=date,
            location=location,
        )

        return self.match_repo.create(db, match)

    # ✏️ Update resultado
    def update_score(
        self,
        db: Session,
        match_id: int,
        home_score: int | None,
        away_score: int | None,
    ) -> Match:

        match = self.get_match(db, match_id)

        if home_score is not None:
            match.home_score = home_score
        if away_score is not None:
            match.away_score = away_score

        db.commit()
        db.refresh(match)

        return match

    # 🗑 Delete
    def delete_match(self, db: Session, match_id: int):
        match = self.get_match(db, match_id)
        self.match_repo.delete(db, match)
