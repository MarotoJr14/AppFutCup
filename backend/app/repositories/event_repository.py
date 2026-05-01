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

    def get_all(self, skip: int = 0, limit: int | None = None) -> list[Event]:
        query = self.db.query(Event).offset(skip)
        if limit is not None:
            query = query.limit(limit)
        return query.all()

    def get_top_scorers(self, tournament_id: int, limit: int = 20):
        from app.models.match import Match
        from app.models.player import Player
        from app.models.player_team import PlayerTeam
        from app.models.team import Team
        from sqlalchemy.orm import aliased
        from app.models.lineup import Lineup
        from app.models.enums import LineupRole

        lineup_match = aliased(Match)
        matches_played_sq = (
            self.db.query(
                Lineup.player_id.label("player_id"),
                func.count(func.distinct(Lineup.match_id)).label("matches_played"),
            )
            .join(lineup_match, lineup_match.id == Lineup.match_id)
            .filter(
                lineup_match.tournament_id == tournament_id,
                Lineup.role.in_([LineupRole.Starter, LineupRole.Bench]),
            )
            .group_by(Lineup.player_id)
        ).subquery()

        matches_played = func.coalesce(matches_played_sq.c.matches_played, 999999)

        return (
            self.db.query(
                Player.id.label("player_id"),
                Player.name.label("player_name"),
                Team.name.label("team_name"),
                func.count(Event.id).label("goals"),
                matches_played_sq.c.matches_played.label("matches_played"),
            )
            .join(Event, Event.player_id == Player.id)
            .join(Match, Match.id == Event.match_id)
            .join(PlayerTeam, (PlayerTeam.player_id == Player.id) & (PlayerTeam.team_id == Event.team_id))
            .join(Team, Team.id == Event.team_id)
            .outerjoin(matches_played_sq, matches_played_sq.c.player_id == Player.id)
            .filter(
                Match.tournament_id == tournament_id,
                Event.event_type == EventType.Goal,
            )
            .group_by(Player.id, Player.name, Team.name, matches_played_sq.c.matches_played)
            .order_by(
                func.count(Event.id).desc(),
                matches_played.asc(),
                Team.name.asc(),
                Player.name.asc(),
            )
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
