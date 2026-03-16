from sqlalchemy.orm import Session
from app.models.tournament import Tournament


class TournamentRepository:

    def get_by_id(self, db: Session, tournament_id: int) -> Tournament | None:
        return db.query(Tournament).filter(Tournament.id == tournament_id).first()

    def get_by_name_year(self, db: Session, name: str, year: int) -> Tournament | None:
        return (
            db.query(Tournament)
            .filter(Tournament.name == name, Tournament.year == year)
            .first()
        )

    def list(self, db: Session) -> list[Tournament]:
        return db.query(Tournament).all()

    def create(self, db: Session, tournament: Tournament) -> Tournament:
        db.add(tournament)
        db.commit()
        db.refresh(tournament)
        return tournament

    def delete(self, db: Session, tournament: Tournament) -> None:
        db.delete(tournament)
        db.commit()
