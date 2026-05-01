from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories.player_repository import PlayerRepository
from app.services.audit_log_service import AuditLogService
from app.schemas.player_schema import PlayerCreate, PlayerUpdate, is_valid_dni, make_placeholder_dni
from app.models.player import Player
from app.models.enums import AuditEntity, AuditAction


class PlayerService:
    def __init__(self, db: Session):
        self.repo = PlayerRepository(db)
        self.audit = AuditLogService(db)

    def _repair_invalid_dnis(self, players: list[Player]) -> None:
        dirty = False
        for player in players:
            if player.id is None:
                continue
            if not is_valid_dni(player.dni):
                player.dni = make_placeholder_dni(player.id)
                dirty = True

        if dirty:
            try:
                self.repo.db.commit()
            except Exception:
                self.repo.db.rollback()
                raise

    def get_all(self, skip: int = 0, limit: int | None = None) -> list[Player]:
        players = self.repo.get_all(skip, limit)
        self._repair_invalid_dnis(players)
        return players

    def get_by_id(self, player_id: int) -> Player:
        p = self.repo.get_by_id(player_id)
        if not p:
            raise HTTPException(status_code=404, detail="Jugador no encontrado")
        self._repair_invalid_dnis([p])
        return p

    def get_by_dni(self, dni: str) -> Player | None:
        return self.repo.get_by_dni(dni)

    def create(self, data: PlayerCreate, actor_id: int) -> Player:
        if self.repo.get_by_dni(data.dni):
            raise HTTPException(status_code=400, detail="Ya existe un jugador con ese DNI")
        player = self.repo.create(data)
        self.audit.log(AuditEntity.Player, AuditAction.Create, actor_id, f"player_id={player.id}")
        return player

    def update(self, player_id: int, data: PlayerUpdate, actor_id: int) -> Player:
        player = self.get_by_id(player_id)
        if data.dni and data.dni != player.dni and self.repo.get_by_dni(data.dni):
            raise HTTPException(status_code=400, detail="Ya existe un jugador con ese DNI")
        updated = self.repo.update(player, data)
        self.audit.log(AuditEntity.Player, AuditAction.Update, actor_id, f"player_id={player_id}")
        return updated

    def delete(self, player_id: int, actor_id: int) -> None:
        player = self.get_by_id(player_id)
        self.repo.delete(player)
        self.audit.log(AuditEntity.Player, AuditAction.Delete, actor_id, f"player_id={player_id}")
