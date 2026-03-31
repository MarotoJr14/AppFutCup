from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.api.v1.deps import get_current_user, require_admin
from app.services.user_service import UserService
from app.schemas.user_schema import UserCreate, UserUpdate, UserOut
from app.models.user import User
from app.models.enums import UserRole

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/me", response_model=UserOut)
def update_me(data: UserUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return UserService(db).update(current_user.id, data, actor_id=current_user.id)


@router.get("/", response_model=list[UserOut])
def get_all(skip: int = 0, limit: int = 100, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return UserService(db).get_all(skip, limit)


@router.get("/{user_id}", response_model=UserOut)
def get_by_id(user_id: int, db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return UserService(db).get_by_id(user_id)


@router.post("/", response_model=UserOut, status_code=201)
def create(data: UserCreate, db: Session = Depends(get_db), current_user: User = Depends(require_admin)):
    return UserService(db).create(data, actor_id=current_user.id)


@router.patch("/{user_id}", response_model=UserOut)
def update(user_id: int, data: UserUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != UserRole.admin and current_user.id != user_id:
        from fastapi import HTTPException
        raise HTTPException(status_code=403, detail="No tienes permiso para editar este usuario")
    return UserService(db).update(user_id, data, actor_id=current_user.id)


@router.delete("/{user_id}", status_code=204)
def delete(user_id: int, db: Session = Depends(get_db), current_user: User = Depends(require_admin)):
    UserService(db).delete(user_id, actor_id=current_user.id)
