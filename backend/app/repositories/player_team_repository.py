from sqlalchemy.orm import Session
from app.models.player_team import PlayerTeam


class PlayerTeamRepository:

    def get_by_id(self, db: Session, relation_id: int) -> PlayerTeam | None:
        return db.query(PlayerTeam).filter(PlayerTeam.id == relation_id).first()

    def get_by_player_and_team(
        self, db: Session, player_id: int, team_id: int
    ) -> PlayerTeam | None:
        return (
            db.query(PlayerTeam)
            .filter(
                PlayerTeam.player_id == player_id,
                PlayerTeam.team_id == team_id,
            )
            .first()
        )

    def list(self, db: Session) -> list[PlayerTeam]:
        return db.query(PlayerTeam).all()

    def create(self, db: Session, relation: PlayerTeam) -> PlayerTeam:
        db.add(relation)
        db.commit()
        db.refresh(relation)
        return relation

    def delete(self, db: Session, relation: PlayerTeam) -> None:
        db.delete(relation)
        db.commit()
