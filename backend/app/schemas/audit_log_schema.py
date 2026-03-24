from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from app.models.enums import AuditEntity, AuditAction


class AuditLogOut(BaseModel):
    id: int
    entity: AuditEntity
    action: AuditAction
    user_id: int
    details: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}
