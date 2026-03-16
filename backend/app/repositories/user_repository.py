from sqlalchemy.orm import Session
from app.models.user import User


class UserRepository:

    # 🔎 Obtener por ID
    def get_by_id(self, db: Session, user_id: int) -> User | None:
        return db.query(User).filter(User.id == user_id).first()

    # 🔎 Obtener por email
    def get_by_email(self, db: Session, email: str) -> User | None:
        return db.query(User).filter(User.email == email).first()

    # 🔎 Obtener por username
    def get_by_username(self, db: Session, username: str) -> User | None:
        return db.query(User).filter(User.username == username).first()

    # 📋 Listar todos
    def list(self, db: Session) -> list[User]:
        return db.query(User).all()

    # ➕ Crear usuario
    def create(self, db: Session, user: User) -> User:
        db.add(user)
        db.commit()
        db.refresh(user)
        return user

    # 🗑 Eliminar usuario
    def delete(self, db: Session, user: User) -> None:
        db.delete(user)
        db.commit()
