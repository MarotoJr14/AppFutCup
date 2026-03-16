from sqlalchemy.orm import Session
from app.models.tournament import Tournament
from app.repositories.tournament_repository import TournamentRepository


class TournamentService:

    def __init__(self):
        self.tournament_repo = TournamentRepository()

    # 🔎 Obtener por ID
    def get_tournament(self, db: Session, tournament_id: int) -> Tournament:
        tournament = self.tournament_repo.get_by_id(db, tournament_id)
        if not tournament:
            raise ValueError("Tournament not found")
        return tournament

    # 📋 Listar todos
    def list_tournaments(self, db: Session) -> list[Tournament]:
        return self.tournament_repo.list(db)

    # ➕ Crear
    def create_tournament(
        self,
        db: Session,
        name: str,
        year: int,
    ) -> Tournament:

        existing = self.tournament_repo.get_by_name_year(db, name, year)
        if existing:
            raise ValueError("Tournament with this name and year already exists")

        tournament = Tournament(
            name=name,
            year=year,
        )

        return self.tournament_repo.create(db, tournament)

    # ✏️ Actualizar
    def update_tournament(
        self,
        db: Session,
        tournament_id: int,
        name: str | None,
        year: int | None,
    ) -> Tournament:

        tournament = self.get_tournament(db, tournament_id)

        new_name = name if name else tournament.name
        new_year = year if year else tournament.year

        existing = self.tournament_repo.get_by_name_year(db, new_name, new_year)
        if existing and existing.id != tournament_id:
            raise ValueError("Another tournament with this name and year already exists")

        if name:
            tournament.name = name
        if year:
            tournament.year = year

        db.commit()
        db.refresh(tournament)

        return tournament

    # 🗑 Eliminar
    def delete_tournament(self, db: Session, tournament_id: int):
        tournament = self.get_tournament(db, tournament_id)
        self.tournament_repo.delete(db, tournament)
