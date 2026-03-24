from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories.event_repository import EventRepository
from app.repositories.match_repository import MatchRepository
from app.repositories.tournament_repository import TournamentRepository
from app.services.audit_log_service import AuditLogService
from app.utils.tournament_guard import require_active_tournament
from app.schemas.event_schema import EventCreate, EventUpdate
from app.models.event import Event
from app.models.enums import AuditEntity, AuditAction


class EventService:
    def __init__(self, db: Session):
        self.repo = EventRepository(db)
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

    def get_all(self, skip: int = 0, limit: int = 100) -> list[Event]:
        return self.repo.get_all(skip, limit)

    def get_by_id(self, event_id: int) -> Event:
        e = self.repo.get_by_id(event_id)
        if not e:
            raise HTTPException(status_code=404, detail="Evento no encontrado")
        return e

    def get_by_match(self, match_id: int) -> list[Event]:
        return self.repo.get_by_match(match_id)

    def get_top_scorers(self, tournament_id: int, limit: int = 20):
        return self.repo.get_top_scorers(tournament_id, limit)

    def create(self, data: EventCreate, actor_id: int) -> Event:
        self._require_active_by_match(data.match_id)
        event = self.repo.create(data)
        self.audit.log(AuditEntity.Event, AuditAction.Create, actor_id, f"event_id={event.id}")
        return event

    def update(self, event_id: int, data: EventUpdate, actor_id: int) -> Event:
        event = self.get_by_id(event_id)
        self._require_active_by_match(event.match_id)
        updated = self.repo.update(event, data)
        self.audit.log(AuditEntity.Event, AuditAction.Update, actor_id, f"event_id={event_id}")
        return updated

    def delete(self, event_id: int, actor_id: int) -> None:
        event = self.get_by_id(event_id)
        self.repo.delete(event)
        self.audit.log(AuditEntity.Event, AuditAction.Delete, actor_id, f"event_id={event_id}")
