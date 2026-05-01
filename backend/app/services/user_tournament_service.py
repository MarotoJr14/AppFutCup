from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories.user_tournament_repository import UserTournamentRepository
from app.repositories.tournament_repository import TournamentRepository
from app.repositories.user_repository import UserRepository
from app.services.audit_log_service import AuditLogService
from app.schemas.user_tournament_schema import UserTournamentCreate
from app.models.user_tournament import UserTournament
from app.models.enums import AuditEntity, AuditAction


class UserTournamentService:
    def __init__(self, db: Session):
        self.repo = UserTournamentRepository(db)
        self.tournament_repo = TournamentRepository(db)
        self.user_repo = UserRepository(db)
        self.audit = AuditLogService(db)

    def get_all(self, skip: int = 0, limit: int | None = None) -> list[UserTournament]:
        return self.repo.get_all(skip, limit)

    def get_by_user(self, user_id: int) -> list[UserTournament]:
        return self.repo.get_by_user(user_id)

    def follow(self, data: UserTournamentCreate, actor_id: int) -> UserTournament:
        if not self.user_repo.get_by_id(data.user_id):
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        if not self.tournament_repo.get_by_id(data.tournament_id):
            raise HTTPException(status_code=404, detail="Torneo no encontrado")
        if self.repo.get_by_user_and_tournament(data.user_id, data.tournament_id):
            raise HTTPException(status_code=400, detail="Ya estás siguiendo este torneo")
        ut = self.repo.create(data)
        self.audit.log(AuditEntity.User_tournament, AuditAction.Create, actor_id,
                       f"user_id={data.user_id} tournament_id={data.tournament_id}")
        return ut

    def unfollow(self, user_id: int, tournament_id: int, actor_id: int) -> None:
        ut = self.repo.get_by_user_and_tournament(user_id, tournament_id)
        if not ut:
            raise HTTPException(status_code=404, detail="No estás siguiendo este torneo")
        self.repo.delete(ut)
        self.audit.log(AuditEntity.User_tournament, AuditAction.Delete, actor_id,
                       f"user_id={user_id} tournament_id={tournament_id}")

    def delete_by_id(self, ut_id: int, actor_id: int) -> None:
        ut = self.repo.get_by_id(ut_id)
        if not ut:
            raise HTTPException(status_code=404, detail="Registro no encontrado")
        self.repo.delete(ut)
        self.audit.log(AuditEntity.User_tournament, AuditAction.Delete, actor_id, f"user_tournament_id={ut_id}")
