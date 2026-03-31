from typing import Optional
from sqlalchemy.orm import Session
from app.models.player_team import PlayerTeam
from app.models.player import Player
from app.schemas.player_team_schema import PlayerTeamCreate, PlayerTeamUpdate


class PlayerTeamRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, pt_id: int) -> Optional[PlayerTeam]:
        return self.db.query(PlayerTeam).filter(PlayerTeam.id == pt_id).first()

    def get_by_team(self, team_id: int) -> list[PlayerTeam]:
        return self.db.query(PlayerTeam).filter(PlayerTeam.team_id == team_id).order_by(PlayerTeam.number).all()

    def get_by_player(self, player_id: int) -> list[PlayerTeam]:
        return self.db.query(PlayerTeam).filter(PlayerTeam.player_id == player_id).all()

    def get_by_player_and_tournament(self, player_id: int, tournament_id: int) -> Optional[PlayerTeam]:
        from app.models.team import Team

        return (
            self.db.query(PlayerTeam)
            .join(Team, Team.id == PlayerTeam.team_id)
            .filter(PlayerTeam.player_id == player_id, Team.tournament_id == tournament_id)
            .first()
        )

    def get_by_player_and_team(self, player_id: int, team_id: int) -> Optional[PlayerTeam]:
        return self.db.query(PlayerTeam).filter(
            PlayerTeam.player_id == player_id,
            PlayerTeam.team_id == team_id,
        ).first()

    def get_by_number_and_team(self, number: int, team_id: int) -> Optional[PlayerTeam]:
        return self.db.query(PlayerTeam).filter(
            PlayerTeam.number == number,
            PlayerTeam.team_id == team_id,
        ).first()

    def get_all(self, skip: int = 0, limit: int = 100) -> list[PlayerTeam]:
        return self.db.query(PlayerTeam).offset(skip).limit(limit).all()

    def create(self, data: PlayerTeamCreate) -> PlayerTeam:
        pt = PlayerTeam(**data.model_dump())
        self.db.add(pt)
        self.db.commit()
        self.db.refresh(pt)
        return pt

    def update(self, pt: PlayerTeam, data: PlayerTeamUpdate) -> PlayerTeam:
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(pt, field, value)
        self.db.commit()
        self.db.refresh(pt)
        return pt

    def delete(self, pt: PlayerTeam) -> None:
        self.db.delete(pt)
        self.db.commit()
