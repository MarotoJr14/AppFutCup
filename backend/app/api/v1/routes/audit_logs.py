from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.api.v1.deps import require_admin
from app.services.audit_log_service import AuditLogService
from app.schemas.audit_log_schema import AuditLogOut
from app.models.enums import AuditEntity
from app.models.user import User

router = APIRouter(prefix="/audit-logs", tags=["Audit Logs"])


@router.get("/", response_model=list[AuditLogOut])
def get_all(
    skip: int = 0,
    limit: int | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    return AuditLogService(db).get_all(skip, limit)


@router.get("/by-entity/{entity}", response_model=list[AuditLogOut])
def get_by_entity(
    entity: AuditEntity,
    skip: int = 0,
    limit: int | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    return AuditLogService(db).get_by_entity(entity, skip, limit)


@router.get("/by-user/{user_id}", response_model=list[AuditLogOut])
def get_by_user(
    user_id: int,
    skip: int = 0,
    limit: int | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    return AuditLogService(db).get_by_user(user_id, skip, limit)
