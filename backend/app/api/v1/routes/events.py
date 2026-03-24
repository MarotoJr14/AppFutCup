from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_org, require_admin
from app.services.event_service import EventService
from app.schemas.event_schema import EventCreate, EventUpdate, EventOut
from app.models.user import User

router = APIRouter(prefix="/events", tags=["Events"])


@router.get("/top-scorers", response_model=list[dict])
def top_scorers(tournament_id: int, limit: int = 20,
                db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    rows = EventService(db).get_top_scorers(tournament_id, limit)
    return [
        {"player_id": r.player_id, "player_name": r.player_name, "team_name": r.team_name, "goals": r.goals}
        for r in rows
    ]


@router.get("/", response_model=list[EventOut])
def get_all(match_id: int | None = None, skip: int = 0, limit: int = 100,
            db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    svc = EventService(db)
    if match_id:
        return svc.get_by_match(match_id)
    return svc.get_all(skip, limit)


@router.get("/{event_id}", response_model=EventOut)
def get_by_id(event_id: int, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    return EventService(db).get_by_id(event_id)


@router.post("/", response_model=EventOut, status_code=201)
def create(data: EventCreate, db: Session = Depends(get_db), _: User = Depends(require_org)):
    return EventService(db).create(data)


@router.patch("/{event_id}", response_model=EventOut)
def update(event_id: int, data: EventUpdate, db: Session = Depends(get_db), _: User = Depends(require_org)):
    return EventService(db).update(event_id, data)


@router.delete("/{event_id}", status_code=204)
def delete(event_id: int, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    EventService(db).delete(event_id)
