from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories.team_repository import TeamRepository
from app.repositories.tournament_repository import TournamentRepository
from app.services.audit_log_service import AuditLogService
from app.utils.tournament_guard import require_active_tournament
from app.schemas.team_schema import TeamCreate, TeamUpdate
from app.models.team import Team
from app.models.enums import AuditEntity, AuditAction


class TeamService:
    def __init__(self, db: Session):
        self.repo = TeamRepository(db)
        self.tournament_repo = TournamentRepository(db)
        self.audit = AuditLogService(db)

    def _get_tournament_or_404(self, tournament_id: int):
        t = self.tournament_repo.get_by_id(tournament_id)
        if not t:
            raise HTTPException(status_code=404, detail="Torneo no encontrado")
        return t

    def get_all(self, skip: int = 0, limit: int | None = None) -> list[Team]:
        return self.repo.get_all(skip, limit)

    def get_by_id(self, team_id: int) -> Team:
        t = self.repo.get_by_id(team_id)
        if not t:
            raise HTTPException(status_code=404, detail="Equipo no encontrado")
        return t

    def get_by_tournament(self, tournament_id: int) -> list[Team]:
        return self.repo.get_by_tournament(tournament_id)

    def create(self, data: TeamCreate, actor_id: int) -> Team:
        tournament = self._get_tournament_or_404(data.tournament_id)
        require_active_tournament(tournament)
        if self.repo.get_by_name_and_tournament(data.name, data.tournament_id):
            raise HTTPException(status_code=400, detail="Ya existe un equipo con ese nombre en este torneo")
        team = self.repo.create(data)
        self.audit.log(AuditEntity.Team, AuditAction.Create, actor_id, f"team_id={team.id}")
        return team

    def update(self, team_id: int, data: TeamUpdate, actor_id: int) -> Team:
        team = self.get_by_id(team_id)
        tournament = self._get_tournament_or_404(team.tournament_id)
        require_active_tournament(tournament)
        if data.name and data.name != team.name:
            if self.repo.get_by_name_and_tournament(data.name, team.tournament_id):
                raise HTTPException(status_code=400, detail="Ya existe un equipo con ese nombre en este torneo")
        updated = self.repo.update(team, data)
        self.audit.log(AuditEntity.Team, AuditAction.Update, actor_id, f"team_id={team_id}")
        return updated

    def delete(self, team_id: int, actor_id: int) -> None:
        team = self.get_by_id(team_id)
        self.repo.delete(team)
        self.audit.log(AuditEntity.Team, AuditAction.Delete, actor_id, f"team_id={team_id}")
