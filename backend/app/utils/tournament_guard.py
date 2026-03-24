from fastapi import HTTPException
from app.models.tournament import Tournament


def require_active_tournament(tournament: Tournament) -> None:
    """Raises 403 if the tournament is not active."""
    if not tournament.is_active:
        raise HTTPException(
            status_code=403,
            detail="Esta operación solo está permitida en torneos activos",
        )
