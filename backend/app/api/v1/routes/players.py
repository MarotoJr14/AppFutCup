from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_org, require_admin
from app.services.player_service import PlayerService
from app.schemas.player_schema import PlayerCreate, PlayerUpdate, PlayerOut
from app.models.user import User

router = APIRouter(prefix="/players", tags=["Players"])


@router.get("/", response_model=list[PlayerOut])
def get_all(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    return PlayerService(db).get_all(skip, limit)


@router.get("/search-dni/{dni}", response_model=PlayerOut | None)
def search_by_dni(dni: str, db: Session = Depends(get_db), _: User = Depends(require_org)):
    return PlayerService(db).get_by_dni(dni)


@router.get("/{player_id}", response_model=PlayerOut)
def get_by_id(player_id: int, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    return PlayerService(db).get_by_id(player_id)


@router.post("/", response_model=PlayerOut, status_code=201)
def create(data: PlayerCreate, db: Session = Depends(get_db), _: User = Depends(require_org)):
    return PlayerService(db).create(data)


@router.patch("/{player_id}", response_model=PlayerOut)
def update(player_id: int, data: PlayerUpdate, db: Session = Depends(get_db), _: User = Depends(require_org)):
    return PlayerService(db).update(player_id, data)


@router.delete("/{player_id}", status_code=204)
def delete(player_id: int, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    PlayerService(db).delete(player_id)
