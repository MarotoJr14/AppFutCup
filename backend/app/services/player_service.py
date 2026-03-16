from sqlalchemy.orm import Session
from app.models.player import Player
from app.repositories.player_repository import PlayerRepository
from app.repositories.team_repository import TeamRepository


class PlayerService:

    def __init__(self):
        self.player_repo = PlayerRepository()
        self.team_repo = TeamRepository()

    # 🔎 Get
    def get_player(self, db: Session, player_id: int) -> Player:
        player = self.player_repo.get_by_id(db, player_id)
        if not player:
            raise ValueError("Player not found")
        return player

    # 📋 List
    def list_players(
        self,
        db: Session,
        team_id: int | None = None,
    ) -> list[Player]:
        return self.player_repo.list(db, team_id)

    # ➕ Create
    def create_player(
        self,
        db: Session,
        name: str,
        number: int,
        position: str,
        team_id: int,
    ) -> Player:

        # 1️⃣ Validar equipo
        team = self.team_repo.get_by_id(db, team_id)
        if not team:
            raise ValueError("Team not found")

        # 2️⃣ Dorsal único por equipo (recomendado)
        existing = self.player_repo.get_by_number_in_team(
            db,
            number,
            team_id,
        )
        if existing:
            raise ValueError("Number already used in this team")

        player = Player(
            name=name,
            number=number,
            position=position,
            team_id=team_id,
        )

        return self.player_repo.create(db, player)

    # ✏️ Update
    def update_player(
        self,
        db: Session,
        player_id: int,
        name: str | None,
        number: int | None,
        position: str | None,
    ) -> Player:

        player = self.get_player(db, player_id)

        # Validar dorsal si cambia
        if number and number != player.number:
            existing = self.player_repo.get_by_number_in_team(
                db,
                number,
                player.team_id,
            )
            if existing:
                raise ValueError("Number already used in this team")

        if name:
            player.name = name
        if number:
            player.number = number
        if position:
            player.position = position

        db.commit()
        db.refresh(player)

        return player

    # 🗑 Delete
    def delete_player(self, db: Session, player_id: int):
        player = self.get_player(db, player_id)
        self.player_repo.delete(db, player)
