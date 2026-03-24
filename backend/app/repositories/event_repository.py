from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.event import Event
from app.models.enums import EventType
from app.schemas.event_schema import EventCreate, EventUpdate


class EventRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, event_id: int) -> Optional[Event]:
        return self.db.query(Event).filter(Event.id == event_id).first()

    def get_by_match(self, match_id: int) -> list[Event]:
        return self.db.query(Event).filter(Event.match_id == match_id).order_by(Event.minute).all()

    def get_by_player(self, player_id: int) -> list[Event]:
        return self.db.query(Event).filter(Event.player_id == player_id).all()

    def get_all(self, skip: int = 0, limit: int = 100) -> list[Event]:
        return self.db.query(Event).offset(skip).limit(limit).all()

    def get_top_scorers(self, tournament_id: int, limit: int = 20):
        from app.models.match import Match
        from app.models.player import Player
        from app.models.player_team import PlayerTeam
        from app.models.team import Team

        return (
            self.db.query(
                Player.id.label("player_id"),
                Player.name.label("player_name"),
                Team.name.label("team_name"),
                func.count(Event.id).label("goals"),
            )
            .join(Event, Event.player_id == Player.id)
            .join(Match, Match.id == Event.match_id)
            .join(PlayerTeam, (PlayerTeam.player_id == Player.id) & (PlayerTeam.team_id == Event.team_id))
            .join(Team, Team.id == Event.team_id)
            .filter(
                Match.tournament_id == tournament_id,
                Event.event_type == EventType.Goal,
            )
            .group_by(Player.id, Player.name, Team.name)
            .order_by(func.count(Event.id).desc())
            .limit(limit)
            .all()
        )

    def create(self, data: EventCreate) -> Event:
        event = Event(**data.model_dump())
        self.db.add(event)
        self.db.commit()
        self.db.refresh(event)
        return event

    def update(self, event: Event, data: EventUpdate) -> Event:
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(event, field, value)
        self.db.commit()
        self.db.refresh(event)
        return event

    def delete(self, event: Event) -> None:
        self.db.delete(event)
        self.db.commit()
