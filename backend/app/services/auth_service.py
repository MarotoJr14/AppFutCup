from sqlalchemy.orm import Session
from sqlalchemy import select

from app.models.user import User
from app.core.security import (
    verify_password,
    hash_password,
    create_access_token,
)


# 🔹 Excepción propia del servicio
class AuthError(Exception):
    pass


# =========================
# REGISTER
# =========================
def register(
    db: Session,
    email: str,
    password: str,
    role: str,
    username: str | None = None,
) -> str:
    # 1️⃣ Comprobar si ya existe
    existing = db.scalar(select(User).where(User.email == email))
    if existing:
        raise AuthError("Email already registered")

    # 2️⃣ Crear usuario
    user = User(
        username=username,
        email=email,
        password_hash=hash_password(password),
        role=role,
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    # 3️⃣ Crear token
    return create_access_token(subject=user.email, role=user.role)


# =========================
# LOGIN
# =========================
def login(db: Session, email: str, password: str) -> str:
    # 1️⃣ Buscar usuario
    user = db.scalar(select(User).where(User.email == email))

    if not user:
        raise AuthError("Invalid credentials")

    # 2️⃣ Verificar password
    if not verify_password(password, user.hashed_password):
        raise AuthError("Invalid credentials")

    # 3️⃣ Generar token
    return create_access_token(subject=user.email, role=user.role)
