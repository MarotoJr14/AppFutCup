from sqlalchemy.orm import Session
from app.models.team import Team
from app.repositories.team_repository import TeamRepository
from app.repositories.tournament_repository import TournamentRepository


class TeamService:

    def __init__(self):
        self.team_repo = TeamRepository()
        self.tournament_repo = TournamentRepository()

    # 🔎 Obtener equipo
    def get_team(self, db: Session, team_id: int) -> Team:
        team = self.team_repo.get_by_id(db, team_id)
        if not team:
            raise ValueError("Team not found")
        return team

    # 📋 Listar equipos (opcional filtro por torneo)
    def list_teams(
        self,
        db: Session,
        tournament_id: int | None = None,
    ) -> list[Team]:
        return self.team_repo.list(db, tournament_id)

    # ➕ Crear equipo
    def create_team(
        self,
        db: Session,
        name: str,
        group: str,
        kit_color: str,
        tournament_id: int,
        logo_url: str | None = None,
    ) -> Team:

        # 1️⃣ Validar torneo
        tournament = self.tournament_repo.get_by_id(db, tournament_id)
        if not tournament:
            raise ValueError("Tournament not found")

        # 2️⃣ Evitar duplicado en el mismo torneo
        existing = self.team_repo.get_by_name_in_tournament(
            db,
            name,
            tournament_id,
        )

        if existing:
            raise ValueError("Team name already exists in this tournament")

        team = Team(
            name=name,
            group=group,
            kit_color=kit_color,
            tournament_id=tournament_id,
            logo_url=logo_url,
        )

        return self.team_repo.create(db, team)

    # ✏️ Actualizar equipo
    def update_team(
        self,
        db: Session,
        team_id: int,
        name: str | None,
        group: str | None,
        kit_color: str | None,
        logo_url: str | None,
    ) -> Team:

        team = self.get_team(db, team_id)

        # Validar unicidad si cambia el nombre
        if name and name != team.name:
            existing = self.team_repo.get_by_name_in_tournament(
                db,
                name,
                team.tournament_id,
            )
            if existing:
                raise ValueError(
                    "Another team with this name already exists in this tournament"
                )

        if name:
            team.name = name
        if group:
            team.group = group
        if kit_color:
            team.kit_color = kit_color
        if logo_url is not None:
            team.logo_url = logo_url

        db.commit()
        db.refresh(team)

        return team

    # 🗑 Eliminar equipo
    def delete_team(self, db: Session, team_id: int):
        team = self.get_team(db, team_id)
        self.team_repo.delete(db, team)
