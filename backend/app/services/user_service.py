from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories.user_repository import UserRepository
from app.services.audit_log_service import AuditLogService
from app.schemas.user_schema import UserCreate, UserUpdate
from app.models.user import User
from app.models.enums import AuditEntity, AuditAction
from app.core.security import verify_password


class UserService:
    def __init__(self, db: Session):
        self.repo = UserRepository(db)
        self.audit = AuditLogService(db)

    def get_all(self, skip: int = 0, limit: int | None = None) -> list[User]:
        return self.repo.get_all(skip, limit)

    def get_by_id(self, user_id: int) -> User:
        user = self.repo.get_by_id(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        return user

    def create(self, data: UserCreate, actor_id: int) -> User:
        if self.repo.get_by_email(data.email):
            raise HTTPException(status_code=400, detail="El email ya está registrado")
        if self.repo.get_by_username(data.username):
            raise HTTPException(status_code=400, detail="El nombre de usuario ya está en uso")
        user = self.repo.create(data)
        self.audit.log(AuditEntity.User, AuditAction.Create, actor_id, f"user_id={user.id}")
        return user

    def update(self, user_id: int, data: UserUpdate, actor_id: int) -> User:
        user = self.get_by_id(user_id)

        # When changing own password, require and validate current password
        if data.password is not None and actor_id == user_id:
            if not data.current_password:
                raise HTTPException(status_code=400, detail="Debes introducir tu contraseña actual")
            if not verify_password(data.current_password, user.password_hash):
                raise HTTPException(status_code=400, detail="La contraseña actual no es correcta")
        if data.email and data.email != user.email and self.repo.get_by_email(data.email):
            raise HTTPException(status_code=400, detail="El email ya está en uso")
        if data.username and data.username != user.username and self.repo.get_by_username(data.username):
            raise HTTPException(status_code=400, detail="El nombre de usuario ya está en uso")
        updated = self.repo.update(user, data)
        self.audit.log(AuditEntity.User, AuditAction.Update, actor_id, f"user_id={user_id}")
        return updated

    def delete(self, user_id: int, actor_id: int) -> None:
        user = self.get_by_id(user_id)
        self.repo.delete(user)
        self.audit.log(AuditEntity.User, AuditAction.Delete, actor_id, f"user_id={user_id}")
