from typing import Optional
from sqlalchemy.orm import Session
from app.models.team import Team
from app.schemas.team_schema import TeamCreate, TeamUpdate


class TeamRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, team_id: int) -> Optional[Team]:
        return self.db.query(Team).filter(Team.id == team_id).first()

    def get_by_tournament(self, tournament_id: int) -> list[Team]:
        return self.db.query(Team).filter(Team.tournament_id == tournament_id).order_by(Team.name).all()

    def get_by_name_and_tournament(self, name: str, tournament_id: int) -> Optional[Team]:
        return self.db.query(Team).filter(Team.name == name, Team.tournament_id == tournament_id).first()

    def get_all(self, skip: int = 0, limit: int | None = None) -> list[Team]:
        query = self.db.query(Team).offset(skip)
        if limit is not None:
            query = query.limit(limit)
        return query.all()

    def create(self, data: TeamCreate) -> Team:
        team = Team(**data.model_dump())
        self.db.add(team)
        self.db.commit()
        self.db.refresh(team)
        return team

    def update(self, team: Team, data: TeamUpdate) -> Team:
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(team, field, value)
        self.db.commit()
        self.db.refresh(team)
        return team

    def delete(self, team: Team) -> None:
        self.db.delete(team)
        self.db.commit()
