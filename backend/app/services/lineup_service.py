from sqlalchemy.orm import Session
from app.models.lineup import Lineup
from app.repositories.lineup_repository import LineupRepository
from app.repositories.match_repository import MatchRepository
from app.repositories.team_repository import TeamRepository
from app.repositories.player_repository import PlayerRepository


class LineupService:

    def __init__(self):
        self.lineup_repo = LineupRepository()
        self.match_repo = MatchRepository()
        self.team_repo = TeamRepository()
        self.player_repo = PlayerRepository()

    # 🔎 Obtener alineación concreta
    def get_lineup(self, db: Session, lineup_id: int) -> Lineup:
        lineup = self.lineup_repo.get_by_id(db, lineup_id)
        if not lineup:
            raise ValueError("Lineup not found")
        return lineup

    # 📋 Listar alineaciones (por match o por equipo)
    def list_lineups(
        self,
        db: Session,
        match_id: int | None = None,
        team_id: int | None = None,
    ) -> list[Lineup]:
        return self.lineup_repo.list(db, match_id, team_id)

    # ➕ Añadir jugador a alineación
    def add_player_to_lineup(
        self,
        db: Session,
        match_id: int,
        team_id: int,
        player_id: int,
        is_starting: bool,
        position: str | None = None,
    ) -> Lineup:

        # 1️⃣ Validar match
        match = self.match_repo.get_by_id(db, match_id)
        if not match:
            raise ValueError("Match not found")

        # 2️⃣ Validar equipo
        team = self.team_repo.get_by_id(db, team_id)
        if not team:
            raise ValueError("Team not found")

        # 3️⃣ Validar que el equipo juegue el partido
        if team_id not in [match.home_team_id, match.away_team_id]:
            raise ValueError("Team is not part of this match")

        # 4️⃣ Validar jugador
        player = self.player_repo.get_by_id(db, player_id)
        if not player:
            raise ValueError("Player not found")

        # 5️⃣ Validar que el jugador pertenezca al equipo
        if player.team_id != team_id:
            raise ValueError("Player does not belong to this team")

        # 6️⃣ Evitar duplicados en misma alineación
        existing = self.lineup_repo.get_by_match_team_player(
            db,
            match_id,
            team_id,
            player_id,
        )

        if existing:
            raise ValueError("Player already in lineup for this match")

        lineup = Lineup(
            match_id=match_id,
            team_id=team_id,
            player_id=player_id,
            is_starting=is_starting,
            position=position,
        )

        return self.lineup_repo.create(db, lineup)

    # 🗑 Quitar jugador de alineación
    def remove_player_from_lineup(
        self,
        db: Session,
        lineup_id: int,
    ):
        lineup = self.get_lineup(db, lineup_id)
        self.lineup_repo.delete(db, lineup)
