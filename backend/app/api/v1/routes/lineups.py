from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_org, require_admin
from app.services.lineup_service import LineupService
from app.schemas.lineup_schema import LineupCreate, LineupBulkCreate, LineupUpdate, LineupOut
from app.models.user import User

router = APIRouter(prefix="/lineups", tags=["Lineups"])


@router.get("/", response_model=list[LineupOut])
def get_all(match_id: int | None = None, skip: int = 0, limit: int | None = None,
            db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    svc = LineupService(db)
    if match_id:
        return svc.get_by_match(match_id)
    return svc.get_all(skip, limit)


@router.get("/{lineup_id}", response_model=LineupOut)
def get_by_id(lineup_id: int, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    return LineupService(db).get_by_id(lineup_id)


@router.post("/", response_model=LineupOut, status_code=201)
def create(data: LineupCreate, db: Session = Depends(get_db), current_user: User = Depends(require_org)):
    return LineupService(db).create(data, actor_id=current_user.id)


@router.post("/bulk", response_model=list[LineupOut], status_code=201)
def bulk_create(data: LineupBulkCreate, db: Session = Depends(get_db), current_user: User = Depends(require_org)):
    return LineupService(db).bulk_create(data, actor_id=current_user.id)


@router.patch("/{lineup_id}", response_model=LineupOut)
def update(lineup_id: int, data: LineupUpdate, db: Session = Depends(get_db), current_user: User = Depends(require_org)):
    return LineupService(db).update(lineup_id, data, actor_id=current_user.id)


@router.delete("/{lineup_id}", status_code=204)
def delete(lineup_id: int, db: Session = Depends(get_db), current_user: User = Depends(require_admin)):
    LineupService(db).delete(lineup_id, actor_id=current_user.id)
