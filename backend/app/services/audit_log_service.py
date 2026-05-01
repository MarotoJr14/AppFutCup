from sqlalchemy.orm import Session
from app.repositories.audit_log_repository import AuditLogRepository
from app.models.audit_log import AuditLog
from app.models.enums import AuditEntity, AuditAction


class AuditLogService:
    def __init__(self, db: Session):
        self.repo = AuditLogRepository(db)

    def log(
        self,
        entity: AuditEntity,
        action: AuditAction,
        user_id: int,
        details: str | None = None,
    ) -> AuditLog:
        return self.repo.create(entity, action, user_id, details)

    def get_all(self, skip: int = 0, limit: int | None = None) -> list[AuditLog]:
        return self.repo.get_all(skip, limit)

    def get_by_entity(self, entity: AuditEntity, skip: int = 0, limit: int | None = None) -> list[AuditLog]:
        return self.repo.get_by_entity(entity, skip, limit)

    def get_by_user(self, user_id: int, skip: int = 0, limit: int | None = None) -> list[AuditLog]:
        return self.repo.get_by_user(user_id, skip, limit)
