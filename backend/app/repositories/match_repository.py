from sqlalchemy.orm import Session
from app.models.match import Match


class MatchRepository:

    def get_by_id(self, db: Session, match_id: int) -> Match | None:
        return db.query(Match).filter(Match.id == match_id).first()

    def list(
        self, db: Session, tournament_id: int | None = None
    ) -> list[Match]:
        query = db.query(Match)
        if tournament_id:
            query = query.filter(Match.tournament_id == tournament_id)
        return query.all()

    def create(self, db: Session, match: Match) -> Match:
        db.add(match)
        db.commit()
        db.refresh(match)
        return match

    def delete(self, db: Session, match: Match) -> None:
        db.delete(match)
        db.commit()
