from typing import Optional
from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user_schema import UserCreate, UserUpdate
from app.core.security import get_password_hash


class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()

    def get_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email).first()

    def get_by_username(self, username: str) -> Optional[User]:
        return self.db.query(User).filter(User.username == username).first()

    def get_all(self, skip: int = 0, limit: int | None = None) -> list[User]:
        query = self.db.query(User).offset(skip)
        if limit is not None:
            query = query.limit(limit)
        return query.all()

    def create(self, data: UserCreate) -> User:
        user = User(
            username=data.username,
            email=data.email,
            password_hash=get_password_hash(data.password),
            role=data.role,
        )
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def update(self, user: User, data: UserUpdate) -> User:
        if data.username is not None:
            user.username = data.username
        if data.email is not None:
            user.email = data.email
        if data.password is not None:
            user.password_hash = get_password_hash(data.password)
        if data.role is not None:
            user.role = data.role
        self.db.commit()
        self.db.refresh(user)
        return user

    def delete(self, user: User) -> None:
        self.db.delete(user)
        self.db.commit()
