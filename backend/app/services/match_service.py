from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories.match_repository import MatchRepository
from app.repositories.tournament_repository import TournamentRepository
from app.services.audit_log_service import AuditLogService
from app.utils.tournament_guard import require_active_tournament
from app.schemas.match_schema import MatchCreate, MatchUpdate
from app.models.match import Match
from app.models.enums import MatchRound, AuditEntity, AuditAction


class MatchService:
    def __init__(self, db: Session):
        self.repo = MatchRepository(db)
        self.tournament_repo = TournamentRepository(db)
        self.audit = AuditLogService(db)

    def _get_tournament_or_404(self, tournament_id: int):
        t = self.tournament_repo.get_by_id(tournament_id)
        if not t:
            raise HTTPException(status_code=404, detail="Torneo no encontrado")
        return t

    def get_all(self, skip: int = 0, limit: int = 100) -> list[Match]:
        return self.repo.get_all(skip, limit)

    def get_by_id(self, match_id: int) -> Match:
        m = self.repo.get_by_id(match_id)
        if not m:
            raise HTTPException(status_code=404, detail="Partido no encontrado")
        return m

    def get_by_tournament(self, tournament_id: int) -> list[Match]:
        return self.repo.get_by_tournament(tournament_id)

    def get_by_tournament_and_round(self, tournament_id: int, round: MatchRound) -> list[Match]:
        return self.repo.get_by_tournament_and_round(tournament_id, round)

    def create(self, data: MatchCreate, actor_id: int) -> Match:
        tournament = self._get_tournament_or_404(data.tournament_id)
        require_active_tournament(tournament)
        match = self.repo.create(data)
        self.audit.log(AuditEntity.Match, AuditAction.Create, actor_id, f"match_id={match.id}")
        return match

    def update(self, match_id: int, data: MatchUpdate, actor_id: int) -> Match:
        match = self.get_by_id(match_id)
        tournament = self._get_tournament_or_404(match.tournament_id)
        require_active_tournament(tournament)
        updated = self.repo.update(match, data)
        self.audit.log(AuditEntity.Match, AuditAction.Update, actor_id, f"match_id={match_id}")
        return updated

    def delete(self, match_id: int, actor_id: int) -> None:
        match = self.get_by_id(match_id)
        self.repo.delete(match)
        self.audit.log(AuditEntity.Match, AuditAction.Delete, actor_id, f"match_id={match_id}")
