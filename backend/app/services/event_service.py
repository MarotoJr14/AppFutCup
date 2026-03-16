from sqlalchemy.orm import Session
from app.models.event import Event
from app.repositories.event_repository import EventRepository
from app.repositories.match_repository import MatchRepository
from app.repositories.player_repository import PlayerRepository
from app.repositories.team_repository import TeamRepository


class EventService:

    def __init__(self):
        self.event_repo = EventRepository()
        self.match_repo = MatchRepository()
        self.player_repo = PlayerRepository()
        self.team_repo = TeamRepository()

    # 🔎 Get
    def get_event(self, db: Session, event_id: int) -> Event:
        event = self.event_repo.get_by_id(db, event_id)
        if not event:
            raise ValueError("Event not found")
        return event

    # 📋 List
    def list_events(
        self,
        db: Session,
        match_id: int | None = None,
    ) -> list[Event]:
        return self.event_repo.list(db, match_id)

    # ➕ Create
    def create_event(
        self,
        db: Session,
        match_id: int,
        player_id: int,
        event_type: str,
        minute: int,
        description: str | None = None,
    ) -> Event:

        # 1️⃣ Validar match
        match = self.match_repo.get_by_id(db, match_id)
        if not match:
            raise ValueError("Match not found")

        # 2️⃣ Validar jugador
        player = self.player_repo.get_by_id(db, player_id)
        if not player:
            raise ValueError("Player not found")

        # 3️⃣ Validar minuto
        if minute < 0 or minute > 130:
            raise ValueError("Invalid minute")

        # 4️⃣ Validar que el jugador pertenezca a uno de los equipos del match
        player_team_id = player.team_id

        if player_team_id not in [match.home_team_id, match.away_team_id]:
            raise ValueError(
                "Player does not belong to any team in this match"
            )

        # 5️⃣ Validar tipo de evento permitido
        allowed_types = ["goal", "yellow_card", "red_card", "substitution"]

        if event_type not in allowed_types:
            raise ValueError("Invalid event type")

        event = Event(
            match_id=match_id,
            player_id=player_id,
            event_type=event_type,
            minute=minute,
            description=description,
        )

        return self.event_repo.create(db, event)

    # 🗑 Delete
    def delete_event(self, db: Session, event_id: int):
        event = self.get_event(db, event_id)
        self.event_repo.delete(db, event)
