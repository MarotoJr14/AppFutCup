from sqlalchemy import String, Integer, DateTime, ForeignKey, Enum, Index, func
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base
from datetime import datetime
from .enums import EntityType, ActionType

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    entity: Mapped[EntityType] = mapped_column(Enum(EntityType), nullable=False)
    action: Mapped[ActionType] = mapped_column(Enum(ActionType), nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    details: Mapped[str] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )
    
    __table_args__ = (
        Index("ix_audit_entity", "entity"),
        Index("ix_audit_action", "action"),
        Index("ix_audit_user", "user_id"),
        Index("ix_audit_created", "created_at"),
    )
