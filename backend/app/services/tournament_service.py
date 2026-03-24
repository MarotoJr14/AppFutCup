from typing import Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories.tournament_repository import TournamentRepository
from app.services.audit_log_service import AuditLogService
from app.schemas.tournament_schema import TournamentCreate, TournamentUpdate
from app.models.tournament import Tournament
from app.models.enums import AuditEntity, AuditAction


class TournamentService:
    def __init__(self, db: Session):
        self.repo = TournamentRepository(db)
        self.audit = AuditLogService(db)

    def get_all(self, skip: int = 0, limit: int = 100) -> list[Tournament]:
        return self.repo.get_all(skip, limit)

    def get_by_id(self, tournament_id: int) -> Tournament:
        t = self.repo.get_by_id(tournament_id)
        if not t:
            raise HTTPException(status_code=404, detail="Torneo no encontrado")
        return t

    def get_active(self) -> Optional[Tournament]:
        return self.repo.get_active()

    def create(self, data: TournamentCreate, actor_id: int) -> Tournament:
        if self.repo.get_by_name(data.name):
            raise HTTPException(status_code=400, detail="Ya existe un torneo con ese nombre")
        if data.is_active:
            self._deactivate_current(actor_id)
        t = self.repo.create(data)
        self.audit.log(AuditEntity.Tournament, AuditAction.Create, actor_id, f"tournament_id={t.id}")
        return t

    def update(self, tournament_id: int, data: TournamentUpdate, actor_id: int) -> Tournament:
        t = self.get_by_id(tournament_id)
        if data.name and data.name != t.name and self.repo.get_by_name(data.name):
            raise HTTPException(status_code=400, detail="Ya existe un torneo con ese nombre")
        if data.is_active is True:
            self._deactivate_current(actor_id, exclude_id=tournament_id)
        updated = self.repo.update(t, data)
        self.audit.log(AuditEntity.Tournament, AuditAction.Update, actor_id, f"tournament_id={tournament_id}")
        return updated

    def delete(self, tournament_id: int, actor_id: int) -> None:
        t = self.get_by_id(tournament_id)
        self.repo.delete(t)
        self.audit.log(AuditEntity.Tournament, AuditAction.Delete, actor_id, f"tournament_id={tournament_id}")

    def _deactivate_current(self, actor_id: int, exclude_id: int | None = None) -> None:
        active = self.repo.get_active()
        if active and active.id != exclude_id:
            self.repo.update(active, TournamentUpdate(is_active=False))
            self.audit.log(AuditEntity.Tournament, AuditAction.Update, actor_id, f"deactivated tournament_id={active.id}")
