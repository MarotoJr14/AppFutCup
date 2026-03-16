from sqlalchemy.orm import Session
from app.models.lineup import Lineup


class LineupRepository:

    def get_by_id(self, db: Session, lineup_id: int) -> Lineup | None:
        return db.query(Lineup).filter(Lineup.id == lineup_id).first()

    def get_by_match_and_player(
        self, db: Session, match_id: int, player_id: int
    ) -> Lineup | None:
        return (
            db.query(Lineup)
            .filter(
                Lineup.match_id == match_id,
                Lineup.player_id == player_id,
            )
            .first()
        )

    def list(
        self, db: Session, match_id: int | None = None
    ) -> list[Lineup]:
        query = db.query(Lineup)
        if match_id:
            query = query.filter(Lineup.match_id == match_id)
        return query.all()

    def create(self, db: Session, lineup: Lineup) -> Lineup:
        db.add(lineup)
        db.commit()
        db.refresh(lineup)
        return lineup

    def delete(self, db: Session, lineup: Lineup) -> None:
        db.delete(lineup)
        db.commit()
