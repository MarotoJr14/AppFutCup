from typing import Optional
from sqlalchemy.orm import Session
from app.models.lineup import Lineup
from app.schemas.lineup_schema import LineupCreate, LineupUpdate


class LineupRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, lineup_id: int) -> Optional[Lineup]:
        return self.db.query(Lineup).filter(Lineup.id == lineup_id).first()

    def get_by_match(self, match_id: int) -> list[Lineup]:
        return self.db.query(Lineup).filter(Lineup.match_id == match_id).all()

    def get_by_match_and_team(self, match_id: int, team_id: int) -> list[Lineup]:
        return self.db.query(Lineup).filter(
            Lineup.match_id == match_id,
            Lineup.team_id == team_id,
        ).all()

    def get_by_match_team_player(self, match_id: int, team_id: int, player_id: int) -> Optional[Lineup]:
        return self.db.query(Lineup).filter(
            Lineup.match_id == match_id,
            Lineup.team_id == team_id,
            Lineup.player_id == player_id,
        ).first()

    def get_all(self, skip: int = 0, limit: int | None = None) -> list[Lineup]:
        query = self.db.query(Lineup).offset(skip)
        if limit is not None:
            query = query.limit(limit)
        return query.all()

    def create(self, data: LineupCreate) -> Lineup:
        lineup = Lineup(**data.model_dump())
        self.db.add(lineup)
        self.db.commit()
        self.db.refresh(lineup)
        return lineup

    def bulk_create(self, lineups_data: list[LineupCreate]) -> list[Lineup]:
        lineups = [Lineup(**d.model_dump()) for d in lineups_data]
        self.db.add_all(lineups)
        self.db.commit()
        for l in lineups:
            self.db.refresh(l)
        return lineups

    def update(self, lineup: Lineup, data: LineupUpdate) -> Lineup:
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(lineup, field, value)
        self.db.commit()
        self.db.refresh(lineup)
        return lineup

    def delete(self, lineup: Lineup) -> None:
        self.db.delete(lineup)
        self.db.commit()

    def delete_by_match(self, match_id: int) -> None:
        self.db.query(Lineup).filter(Lineup.match_id == match_id).delete()
        self.db.commit()
