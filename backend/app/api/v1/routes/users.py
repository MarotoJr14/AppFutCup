from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_roles
from app.models.user import User
from app.schemas.user import UserResponse, UserCreate, UserUpdate
from app.repositories import user_repository
from app.services.user_service import UserService
from app.core.security import hash_password

router = APIRouter(prefix="/users", tags=["users"])

user_service = UserService()

@router.get("/me", response_model=UserResponse)
def read_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.get("/", response_model=List[UserResponse])
def list_users(
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin")),
):
    return user_service.list(db)

@router.post("/", response_model=UserResponse)
def create_user(
    payload: UserCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin")),
):
    existing = user_repository.get_by_email(db, payload.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    new_user = User(
        username=payload.username,
        email=payload.email,
        password_hash=hash_password(payload.password),
        role=payload.role,
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user

@router.put("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: int,
    payload: UserUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin")),
):
    db_user = user_repository.get_by_id(db, user_id)

    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    if payload.username is not None:
        db_user.username = payload.username

    if payload.email is not None:
        db_user.email = payload.email

    if payload.password is not None:
        db_user.password_hash = hash_password(payload.password)

    if payload.role is not None:
        db_user.role = payload.role

    db.commit()
    db.refresh(db_user)

    return db_user

@router.delete("/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles("admin")),
):
    db_user = user_repository.get_by_id(db, user_id)

    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(db_user)
    db.commit()

    return {"message": "User deleted"}
