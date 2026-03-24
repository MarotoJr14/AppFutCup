from sqlalchemy.orm import Session
from app.models.audit_log import AuditLog
from app.models.enums import AuditEntity, AuditAction


class AuditLogRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_all(self, skip: int = 0, limit: int = 100) -> list[AuditLog]:
        return (
            self.db.query(AuditLog)
            .order_by(AuditLog.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def get_by_entity(self, entity: AuditEntity, skip: int = 0, limit: int = 100) -> list[AuditLog]:
        return (
            self.db.query(AuditLog)
            .filter(AuditLog.entity == entity)
            .order_by(AuditLog.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def get_by_user(self, user_id: int, skip: int = 0, limit: int = 100) -> list[AuditLog]:
        return (
            self.db.query(AuditLog)
            .filter(AuditLog.user_id == user_id)
            .order_by(AuditLog.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def create(self, entity: AuditEntity, action: AuditAction, user_id: int, details: str | None = None) -> AuditLog:
        log = AuditLog(
            entity=entity,
            action=action,
            user_id=user_id,
            details=details,
        )
        self.db.add(log)
        self.db.commit()
        self.db.refresh(log)
        return log
