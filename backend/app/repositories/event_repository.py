from sqlalchemy.orm import Session
from app.models.event import Event


class EventRepository:

    def get_by_id(self, db: Session, event_id: int) -> Event | None:
        return db.query(Event).filter(Event.id == event_id).first()

    def list(
        self, db: Session, match_id: int | None = None
    ) -> list[Event]:
        query = db.query(Event)
        if match_id:
            query = query.filter(Event.match_id == match_id)
        return query.all()

    def create(self, db: Session, event: Event) -> Event:
        db.add(event)
        db.commit()
        db.refresh(event)
        return event

    def delete(self, db: Session, event: Event) -> None:
        db.delete(event)
        db.commit()
