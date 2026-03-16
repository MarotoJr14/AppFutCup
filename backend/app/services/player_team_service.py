from sqlalchemy.orm import Session
from app.models.player_team import PlayerTeam
from app.repositories.player_team_repository import PlayerTeamRepository
from app.repositories.player_repository import PlayerRepository
from app.repositories.team_repository import TeamRepository


class PlayerTeamService:

    def __init__(self):
        self.player_team_repo = PlayerTeamRepository()
        self.player_repo = PlayerRepository()
        self.team_repo = TeamRepository()

    # 🔎 Get
    def get_player_team(self, db: Session, player_team_id: int) -> PlayerTeam:
        player_team = self.player_team_repo.get_by_id(db, player_team_id)
        if not player_team:
            raise ValueError("PlayerTeam relation not found")
        return player_team

    # 📋 List
    def list_player_teams(
        self,
        db: Session,
        team_id: int | None = None,
        player_id: int | None = None,
    ) -> list[PlayerTeam]:
        return self.player_team_repo.list(db, team_id, player_id)

    # ➕ Assign player to team
    def assign_player_to_team(
        self,
        db: Session,
        player_id: int,
        team_id: int,
    ) -> PlayerTeam:

        # 1️⃣ Validar jugador
        player = self.player_repo.get_by_id(db, player_id)
        if not player:
            raise ValueError("Player not found")

        # 2️⃣ Validar equipo
        team = self.team_repo.get_by_id(db, team_id)
        if not team:
            raise ValueError("Team not found")

        # 3️⃣ Evitar duplicado exacto
        existing = self.player_team_repo.get_by_player_and_team(
            db,
            player_id,
            team_id,
        )

        if existing:
            raise ValueError("Player already assigned to this team")
