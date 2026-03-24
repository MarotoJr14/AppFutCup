from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.repositories.user_repository import UserRepository
from app.core.security import verify_password, create_access_token
from app.schemas.auth_schema import Token, LoginRequest
from app.schemas.user_schema import UserCreate
from app.models.enums import UserRole


class AuthService:
    def __init__(self, db: Session):
        self.repo = UserRepository(db)

    def register(self, data: UserCreate):
        # Enforce only "user" role from public registration
        data.role = UserRole.user
        if self.repo.get_by_email(data.email):
            raise HTTPException(status_code=400, detail="El email ya está registrado")
        if self.repo.get_by_username(data.username):
            raise HTTPException(status_code=400, detail="El nombre de usuario ya está en uso")
        return self.repo.create(data)

    def login(self, data: LoginRequest) -> Token:
        user = self.repo.get_by_email(data.email)
        if not user or not verify_password(data.password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciales incorrectas",
                headers={"WWW-Authenticate": "Bearer"},
            )
        token = create_access_token({"sub": str(user.id), "role": user.role.value})
        return Token(access_token=token)
