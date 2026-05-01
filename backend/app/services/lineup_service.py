from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories.lineup_repository import LineupRepository
from app.repositories.match_repository import MatchRepository
from app.repositories.tournament_repository import TournamentRepository
from app.services.audit_log_service import AuditLogService
from app.utils.tournament_guard import require_active_tournament
from app.schemas.lineup_schema import LineupCreate, LineupBulkCreate, LineupUpdate
from app.models.lineup import Lineup
from app.models.enums import AuditEntity, AuditAction, MatchStatus


class LineupService:
    def __init__(self, db: Session):
        self.repo = LineupRepository(db)
        self.match_repo = MatchRepository(db)
        self.tournament_repo = TournamentRepository(db)
        self.audit = AuditLogService(db)

    def _require_active_by_match(self, match_id: int) -> None:
        match = self.match_repo.get_by_id(match_id)
        if not match:
            raise HTTPException(status_code=404, detail="Partido no encontrado")
        tournament = self.tournament_repo.get_by_id(match.tournament_id)
        if not tournament:
            raise HTTPException(status_code=404, detail="Torneo no encontrado")
        require_active_tournament(tournament)

    def get_all(self, skip: int = 0, limit: int | None = None) -> list[Lineup]:
        return self.repo.get_all(skip, limit)

    def get_by_id(self, lineup_id: int) -> Lineup:
        l = self.repo.get_by_id(lineup_id)
        if not l:
            raise HTTPException(status_code=404, detail="Alineación no encontrada")
        return l

    def get_by_match(self, match_id: int) -> list[Lineup]:
        return self.repo.get_by_match(match_id)

    def create(self, data: LineupCreate, actor_id: int) -> Lineup:
        self._require_active_by_match(data.match_id)
        match = self.match_repo.get_by_id(data.match_id)
        if not match:
            raise HTTPException(status_code=404, detail="Partido no encontrado")
        if match.status != MatchStatus.Pending:
            raise HTTPException(status_code=400, detail="Las alineaciones solo se pueden cargar cuando el partido está pendiente")
        if match.team_home_id is None or match.team_away_id is None:
            raise HTTPException(status_code=400, detail="El partido debe tener equipos asignados antes de cargar alineaciones")
        if data.team_id not in (match.team_home_id, match.team_away_id):
            raise HTTPException(status_code=400, detail="El equipo de la alineación debe ser uno de los equipos del partido")
        if self.repo.get_by_match_team_player(data.match_id, data.team_id, data.player_id):
            raise HTTPException(status_code=400, detail="El jugador ya está en la alineación de este partido")
        lineup = self.repo.create(data)
        self.audit.log(AuditEntity.Lineup, AuditAction.Create, actor_id, f"lineup_id={lineup.id}")
        return lineup

    def bulk_create(self, data: LineupBulkCreate, actor_id: int) -> list[Lineup]:
        if not data.lineups:
            return []

        self._require_active_by_match(data.lineups[0].match_id)
        match_id = data.lineups[0].match_id
        match = self.match_repo.get_by_id(match_id)
        if not match:
            raise HTTPException(status_code=404, detail="Partido no encontrado")
        if match.status != MatchStatus.Pending:
            raise HTTPException(status_code=400, detail="Las alineaciones solo se pueden cargar cuando el partido está pendiente")
        if match.team_home_id is None or match.team_away_id is None:
            raise HTTPException(status_code=400, detail="El partido debe tener equipos asignados antes de cargar alineaciones")

        seen = set()
        for item in data.lineups:
            if item.match_id != match_id:
                raise HTTPException(status_code=400, detail="Todas las alineaciones deben pertenecer al mismo partido")
            if item.team_id not in (match.team_home_id, match.team_away_id):
                raise HTTPException(status_code=400, detail="El equipo de la alineación debe ser uno de los equipos del partido")
            key = (item.team_id, item.player_id)
            if key in seen:
                raise HTTPException(status_code=400, detail="Alineación duplicada en el envío")
            seen.add(key)

        # Replace existing lineups for this match (bulk form acts like upsert)
        self.repo.delete_by_match(match_id)
        lineups = self.repo.bulk_create(data.lineups)
        self.audit.log(AuditEntity.Lineup, AuditAction.Create, actor_id,
                       f"bulk {len(lineups)} lineups match_id={match_id}")
        return lineups
    def update(self, lineup_id: int, data: LineupUpdate, actor_id: int) -> Lineup:
        lineup = self.get_by_id(lineup_id)
        self._require_active_by_match(lineup.match_id)
        match = self.match_repo.get_by_id(lineup.match_id)
        if match and match.status != MatchStatus.Pending:
            raise HTTPException(status_code=400, detail="No se pueden modificar alineaciones cuando el partido no está pendiente")
        updated = self.repo.update(lineup, data)
        self.audit.log(AuditEntity.Lineup, AuditAction.Update, actor_id, f"lineup_id={lineup_id}")
        return updated

    def delete(self, lineup_id: int, actor_id: int) -> None:
        lineup = self.get_by_id(lineup_id)
        self.repo.delete(lineup)
        self.audit.log(AuditEntity.Lineup, AuditAction.Delete, actor_id, f"lineup_id={lineup_id}")
