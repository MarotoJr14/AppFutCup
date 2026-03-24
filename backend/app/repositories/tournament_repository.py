from typing import Optional
from sqlalchemy.orm import Session
from app.models.tournament import Tournament
from app.schemas.tournament_schema import TournamentCreate, TournamentUpdate


class TournamentRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, tournament_id: int) -> Optional[Tournament]:
        return self.db.query(Tournament).filter(Tournament.id == tournament_id).first()

    def get_by_name(self, name: str) -> Optional[Tournament]:
        return self.db.query(Tournament).filter(Tournament.name == name).first()
    
    def get_active(self) -> Optional[Tournament]:
        return self.db.query(Tournament).filter(Tournament.is_active == True).first()

    def get_all(self, skip: int = 0, limit: int = 100) -> list[Tournament]:
        return self.db.query(Tournament).offset(skip).limit(limit).all()

    def create(self, data: TournamentCreate) -> Tournament:
        tournament = Tournament(**data.model_dump())
        self.db.add(tournament)
        self.db.commit()
        self.db.refresh(tournament)
        return tournament

    def update(self, tournament: Tournament, data: TournamentUpdate) -> Tournament:
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(tournament, field, value)
        self.db.commit()
        self.db.refresh(tournament)
        return tournament

    def delete(self, tournament: Tournament) -> None:
        self.db.delete(tournament)
        self.db.commit()
