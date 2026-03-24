from typing import Optional
from sqlalchemy.orm import Session
from app.models.player import Player
from app.schemas.player_schema import PlayerCreate, PlayerUpdate


class PlayerRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, player_id: int) -> Optional[Player]:
        return self.db.query(Player).filter(Player.id == player_id).first()

    def get_by_dni(self, dni: str) -> Optional[Player]:
        return self.db.query(Player).filter(Player.dni == dni).first()

    def get_all(self, skip: int = 0, limit: int = 100) -> list[Player]:
        return self.db.query(Player).offset(skip).limit(limit).all()

    def create(self, data: PlayerCreate) -> Player:
        player = Player(**data.model_dump())
        self.db.add(player)
        self.db.commit()
        self.db.refresh(player)
        return player

    def update(self, player: Player, data: PlayerUpdate) -> Player:
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(player, field, value)
        self.db.commit()
        self.db.refresh(player)
        return player

    def delete(self, player: Player) -> None:
        self.db.delete(player)
        self.db.commit()
