from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_admin
from app.services.user_tournament_service import UserTournamentService
from app.schemas.user_tournament_schema import UserTournamentCreate, UserTournamentOut
from app.models.user import User

router = APIRouter(prefix="/user-tournaments", tags=["User Tournaments"])


@router.get("/", response_model=list[UserTournamentOut])
def get_all(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return UserTournamentService(db).get_all(skip, limit)


@router.get("/me", response_model=list[UserTournamentOut])
def get_my_tournaments(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return UserTournamentService(db).get_by_user(current_user.id)


@router.post("/follow", response_model=UserTournamentOut, status_code=201)
def follow(data: UserTournamentCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    data.user_id = current_user.id
    return UserTournamentService(db).follow(data, actor_id=current_user.id)


@router.delete("/unfollow/{tournament_id}", status_code=204)
def unfollow(tournament_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    UserTournamentService(db).unfollow(current_user.id, tournament_id, actor_id=current_user.id)


@router.delete("/{ut_id}", status_code=204)
def delete(ut_id: int, db: Session = Depends(get_db), current_user: User = Depends(require_admin)):
    UserTournamentService(db).delete_by_id(ut_id, actor_id=current_user.id)
