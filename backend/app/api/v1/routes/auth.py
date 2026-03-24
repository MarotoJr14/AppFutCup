from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.services.auth_service import AuthService
from app.schemas.auth_schema import Token, LoginRequest, RegisterResponse
from app.schemas.user_schema import UserCreate, UserOut

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=RegisterResponse, status_code=201)
def register(data: UserCreate, db: Session = Depends(get_db)):
    user = AuthService(db).register(data)
    return RegisterResponse(message="Usuario creado correctamente", user=UserOut.model_validate(user))


@router.post("/login", response_model=Token)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    return AuthService(db).login(data)
