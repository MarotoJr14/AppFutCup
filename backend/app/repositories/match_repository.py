from typing import Optional
from sqlalchemy.orm import Session
from app.models.match import Match
from app.models.enums import MatchRound, MatchStatus
from app.schemas.match_schema import MatchCreate, MatchUpdate


class MatchRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, match_id: int) -> Optional[Match]:
        return self.db.query(Match).filter(Match.id == match_id).first()

    def get_by_tournament(self, tournament_id: int) -> list[Match]:
        return self.db.query(Match).filter(Match.tournament_id == tournament_id).all()

    def get_by_tournament_and_round(self, tournament_id: int, round: MatchRound) -> list[Match]:
        return self.db.query(Match).filter(
            Match.tournament_id == tournament_id,
            Match.round == round,
        ).all()

    def get_all(self, skip: int = 0, limit: int = 100) -> list[Match]:
        return self.db.query(Match).offset(skip).limit(limit).all()

    def create(self, data: MatchCreate) -> Match:
        match = Match(**data.model_dump())
        self.db.add(match)
        self.db.commit()
        self.db.refresh(match)
        return match

    def update(self, match: Match, data: MatchUpdate) -> Match:
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(match, field, value)
        self.db.commit()
        self.db.refresh(match)
        return match

    def delete(self, match: Match) -> None:
        self.db.delete(match)
        self.db.commit()
