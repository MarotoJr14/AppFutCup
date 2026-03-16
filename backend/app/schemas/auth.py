from pydantic import BaseModel, EmailStr, Field
from typing import Literal


# =========================
# REGISTER REQUEST
# =========================
class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    username: str | None = None


# =========================
# LOGIN REQUEST
# =========================
class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# =========================
# TOKEN RESPONSE
# =========================
class TokenResponse(BaseModel):
    access_token: str
    role: str