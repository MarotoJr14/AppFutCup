from sqlalchemy.orm import Session
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.core.security import hash_password


class UserService:

    def __init__(self):
        self.user_repo = UserRepository()

    def get_user(self, db: Session, user_id: int) -> User:
        user = self.user_repo.get_by_id(db, user_id)
        if not user:
            raise ValueError("User not found")
        return user

    def list_users(self, db: Session) -> list[User]:
        return self.user_repo.list(db)

    def create_user(
        self,
        db: Session,
        email: str,
        username: str,
        password: str,
        role: str,
    ) -> User:

        if self.user_repo.get_by_email(db, email):
            raise ValueError("Email already registered")

        if self.user_repo.get_by_username(db, username):
            raise ValueError("Username already taken")

        user = User(
            email=email,
            username=username,
            password_hash=hash_password(password),
            role=role,
        )

        return self.user_repo.create(db, user)

    def delete_user(self, db: Session, user_id: int):
        user = self.get_user(db, user_id)
        self.user_repo.delete(db, user)
