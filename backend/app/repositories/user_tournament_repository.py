from typing import Optional
from sqlalchemy.orm import Session
from app.models.user_tournament import UserTournament
from app.schemas.user_tournament_schema import UserTournamentCreate


class UserTournamentRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, ut_id: int) -> Optional[UserTournament]:
        return self.db.query(UserTournament).filter(UserTournament.id == ut_id).first()

    def get_by_user_and_tournament(self, user_id: int, tournament_id: int) -> Optional[UserTournament]:
        return self.db.query(UserTournament).filter(
            UserTournament.user_id == user_id,
            UserTournament.tournament_id == tournament_id,
        ).first()

    def get_by_user(self, user_id: int) -> list[UserTournament]:
        return self.db.query(UserTournament).filter(UserTournament.user_id == user_id).all()

    def get_by_tournament(self, tournament_id: int) -> list[UserTournament]:
        return self.db.query(UserTournament).filter(UserTournament.tournament_id == tournament_id).all()

    def get_all(self, skip: int = 0, limit: int | None = None) -> list[UserTournament]:
        query = self.db.query(UserTournament).offset(skip)
        if limit is not None:
            query = query.limit(limit)
        return query.all()

    def create(self, data: UserTournamentCreate) -> UserTournament:
        ut = UserTournament(**data.model_dump())
        self.db.add(ut)
        self.db.commit()
        self.db.refresh(ut)
        return ut

    def delete(self, ut: UserTournament) -> None:
        self.db.delete(ut)
        self.db.commit()
