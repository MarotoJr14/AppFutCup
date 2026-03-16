from sqlalchemy.orm import Session
from app.models.player import Player


class PlayerRepository:

    def get_by_id(self, db: Session, player_id: int) -> Player | None:
        return db.query(Player).filter(Player.id == player_id).first()

    def list(self, db: Session) -> list[Player]:
        return db.query(Player).all()

    def create(self, db: Session, player: Player) -> Player:
        db.add(player)
        db.commit()
        db.refresh(player)
        return player

    def delete(self, db: Session, player: Player) -> None:
        db.delete(player)
        db.commit()
