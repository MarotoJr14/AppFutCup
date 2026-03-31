from datetime import datetime
from typing import Optional
import re
from pydantic import BaseModel, field_validator

_DNI_RE = re.compile(r"^[0-9]{8}[A-Za-z]$")


def _normalize_dni(v: str) -> str:
    dni = (v or "").strip().upper()
    if not _DNI_RE.fullmatch(dni):
        raise ValueError("El DNI debe tener 8 dígitos seguidos de 1 letra (ej: 12345678A)")
    return dni


class PlayerBase(BaseModel):
    name: str
    dni: str

    @field_validator("dni")
    @classmethod
    def validate_dni(cls, v: str) -> str:
        return _normalize_dni(v)


class PlayerCreate(PlayerBase):
    pass


class PlayerUpdate(BaseModel):
    name: Optional[str] = None
    dni: Optional[str] = None

    @field_validator("dni")
    @classmethod
    def validate_dni(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        return _normalize_dni(v)


class PlayerOut(PlayerBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
