from datetime import datetime
from typing import Optional
import re
from pydantic import BaseModel, field_validator

_DNI_RE = re.compile(r"^[XYZ0-9][0-9]{7}[A-Za-z]$")


def is_valid_dni(v: str) -> bool:
    dni = (v or "").strip().upper()
    return bool(_DNI_RE.fullmatch(dni))


def make_placeholder_dni(player_id: int) -> str:
    # Usa formato NIE para minimizar colisiones con DNIs reales.
    return f"X{player_id % 10_000_000:07d}A"


def _normalize_dni(v: str) -> str:
    dni = (v or "").strip().upper()
    if not _DNI_RE.fullmatch(dni):
        raise ValueError("El documento debe ser DNI (8 dígitos + letra) o NIE (X/Y/Z + 7 dígitos + letra, ej: 12345678A o X1234567A)")
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
