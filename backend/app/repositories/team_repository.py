from sqlalchemy.orm import Session
from app.models.team import Team


class TeamRepository:

    def get_by_id(self, db: Session, team_id: int) -> Team | None:
        return db.query(Team).filter(Team.id == team_id).first()

    def list(self, db: Session, tournament_id: int | None = None) -> list[Team]:
        query = db.query(Team)
        if tournament_id:
            query = query.filter(Team.tournament_id == tournament_id)
        return query.all()

    def get_by_name_in_tournament(
        self, db: Session, name: str, tournament_id: int
    ) -> Team | None:
        return (
            db.query(Team)
            .filter(Team.name == name, Team.tournament_id == tournament_id)
            .first()
        )

    def create(self, db: Session, team: Team) -> Team:
        db.add(team)
        db.commit()
        db.refresh(team)
        return team

    def delete(self, db: Session, team: Team) -> None:
        db.delete(team)
        db.commit()
