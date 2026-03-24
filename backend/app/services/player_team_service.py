from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories.player_team_repository import PlayerTeamRepository
from app.repositories.player_repository import PlayerRepository
from app.repositories.team_repository import TeamRepository
from app.repositories.tournament_repository import TournamentRepository
from app.services.audit_log_service import AuditLogService
from app.utils.tournament_guard import require_active_tournament
from app.schemas.player_team_schema import PlayerTeamCreate, PlayerTeamUpdate
from app.schemas.player_schema import PlayerCreate
from app.models.player_team import PlayerTeam
from app.models.enums import AuditEntity, AuditAction


class PlayerTeamService:
    def __init__(self, db: Session):
        self.repo = PlayerTeamRepository(db)
        self.player_repo = PlayerRepository(db)
        self.team_repo = TeamRepository(db)
        self.tournament_repo = TournamentRepository(db)
        self.audit = AuditLogService(db)

    def _require_active_by_team(self, team_id: int) -> None:
        team = self.team_repo.get_by_id(team_id)
        if not team:
            raise HTTPException(status_code=404, detail="Equipo no encontrado")
        tournament = self.tournament_repo.get_by_id(team.tournament_id)
        if not tournament:
            raise HTTPException(status_code=404, detail="Torneo no encontrado")
        require_active_tournament(tournament)

    def get_all(self, skip: int = 0, limit: int = 100) -> list[PlayerTeam]:
        return self.repo.get_all(skip, limit)

    def get_by_id(self, pt_id: int) -> PlayerTeam:
        pt = self.repo.get_by_id(pt_id)
        if not pt:
            raise HTTPException(status_code=404, detail="Relación jugador-equipo no encontrada")
        return pt

    def get_by_team(self, team_id: int) -> list[PlayerTeam]:
        return self.repo.get_by_team(team_id)

    def add_player_to_team(self, data: PlayerTeamCreate, actor_id: int) -> PlayerTeam:
        self._require_active_by_team(data.team_id)
        if not self.player_repo.get_by_id(data.player_id):
            raise HTTPException(status_code=404, detail="Jugador no encontrado")
        if self.repo.get_by_player_and_team(data.player_id, data.team_id):
            raise HTTPException(status_code=400, detail="El jugador ya está en este equipo")
        if self.repo.get_by_number_and_team(data.number, data.team_id):
            raise HTTPException(status_code=400, detail="El dorsal ya está en uso en este equipo")
        pt = self.repo.create(data)
        self.audit.log(AuditEntity.Player_team, AuditAction.Create, actor_id,
                       f"player_id={data.player_id} team_id={data.team_id}")
        return pt

    def register_player(self, dni: str, name: str | None, team_id: int, number: int, actor_id: int) -> PlayerTeam:
        """Create player if not exists, then add to team."""
        self._require_active_by_team(team_id)
        player = self.player_repo.get_by_dni(dni)
        if not player:
            if not name:
                raise HTTPException(status_code=400, detail="Nombre requerido para nuevo jugador")
            player = self.player_repo.create(PlayerCreate(name=name, dni=dni))
            self.audit.log(AuditEntity.Player, AuditAction.Create, actor_id, f"player_id={player.id} via register")
        data = PlayerTeamCreate(player_id=player.id, team_id=team_id, number=number)
        if self.repo.get_by_player_and_team(player.id, team_id):
            raise HTTPException(status_code=400, detail="El jugador ya está en este equipo")
        if self.repo.get_by_number_and_team(number, team_id):
            raise HTTPException(status_code=400, detail="El dorsal ya está en uso en este equipo")
        pt = self.repo.create(data)
        self.audit.log(AuditEntity.Player_team, AuditAction.Create, actor_id,
                       f"player_id={player.id} team_id={team_id}")
        return pt

    def update(self, pt_id: int, data: PlayerTeamUpdate, actor_id: int) -> PlayerTeam:
        pt = self.get_by_id(pt_id)
        if data.number and data.number != pt.number:
            if self.repo.get_by_number_and_team(data.number, pt.team_id):
                raise HTTPException(status_code=400, detail="El dorsal ya está en uso en este equipo")
        updated = self.repo.update(pt, data)
        self.audit.log(AuditEntity.Player_team, AuditAction.Update, actor_id, f"player_team_id={pt_id}")
        return updated

    def delete(self, pt_id: int, actor_id: int) -> None:
        pt = self.get_by_id(pt_id)
        self.repo.delete(pt)
        self.audit.log(AuditEntity.Player_team, AuditAction.Delete, actor_id, f"player_team_id={pt_id}")
