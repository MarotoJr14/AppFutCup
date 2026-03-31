from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories.match_repository import MatchRepository
from app.repositories.team_repository import TeamRepository
from app.repositories.tournament_repository import TournamentRepository
from app.repositories.lineup_repository import LineupRepository
from app.services.audit_log_service import AuditLogService
from app.utils.tournament_guard import require_active_tournament
from app.schemas.match_schema import MatchCreate, MatchUpdate
from app.models.match import Match
from app.models.enums import MatchRound, MatchStatus, AuditEntity, AuditAction


class MatchService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = MatchRepository(db)
        self.team_repo = TeamRepository(db)
        self.tournament_repo = TournamentRepository(db)
        self.lineup_repo = LineupRepository(db)
        self.audit = AuditLogService(db)

    def _previous_round(self, round: MatchRound) -> MatchRound | None:
        order = {
            MatchRound.RoundOf16: None,
            MatchRound.Quarterfinal: MatchRound.RoundOf16,
            MatchRound.Semifinal: MatchRound.Quarterfinal,
            MatchRound.Final: MatchRound.Semifinal,
        }
        return order.get(round)

    def _max_matches_for_round(self, round: MatchRound) -> int | None:
        limits = {
            MatchRound.RoundOf16: 8,
            MatchRound.Quarterfinal: 4,
            MatchRound.Semifinal: 2,
            MatchRound.Final: 1,
        }
        return limits.get(round)

    def _validate_round_dependencies(self, tournament_id: int, round: MatchRound) -> None:
        """
        Prevent creating "later round" matches unless enough matches exist in the previous round.

        Rule: to create the (k-th) match of a round, there must be at least 2*k matches created
        in the previous round. Example: to create Semi #2 -> need 4 Quarterfinals.
        """
        prev_round = self._previous_round(round)
        if prev_round is None:
            return

        prev_count = len(self.repo.get_by_tournament_and_round(tournament_id, prev_round))
        current_count = len(self.repo.get_by_tournament_and_round(tournament_id, round))
        needed_prev = 2 * (current_count + 1)

        if prev_count < needed_prev:
            raise HTTPException(
                status_code=400,
                detail=(
                    f"No se puede crear un partido de {round.value} "
                    f"hasta que existan al menos {needed_prev} partidos en {prev_round.value}"
                ),
            )

    def _get_tournament_or_404(self, tournament_id: int):
        t = self.tournament_repo.get_by_id(tournament_id)
        if not t:
            raise HTTPException(status_code=404, detail="Torneo no encontrado")
        return t

    def get_all(self, skip: int = 0, limit: int = 100) -> list[Match]:
        return self.repo.get_all(skip, limit)

    def get_by_id(self, match_id: int) -> Match:
        m = self.repo.get_by_id(match_id)
        if not m:
            raise HTTPException(status_code=404, detail="Partido no encontrado")
        return m

    def get_by_tournament(self, tournament_id: int) -> list[Match]:
        return self.repo.get_by_tournament(tournament_id)

    def get_by_tournament_and_round(self, tournament_id: int, round: MatchRound) -> list[Match]:
        return self.repo.get_by_tournament_and_round(tournament_id, round)

    def create(self, data: MatchCreate, actor_id: int) -> Match:
        tournament = self._get_tournament_or_404(data.tournament_id)
        require_active_tournament(tournament)

        self._validate_round_dependencies(data.tournament_id, data.round)

        limit = self._max_matches_for_round(data.round)
        if limit is not None:
            current = len(self.repo.get_by_tournament_and_round(data.tournament_id, data.round))
            if current >= limit:
                raise HTTPException(
                    status_code=400,
                    detail=f"No se pueden crear más de {limit} partidos en la ronda {data.round.value}",
                )

        # Always create matches as Pending (clients shouldn't control initial status)
        match = self.repo.create(MatchCreate(tournament_id=data.tournament_id, round=data.round, status=MatchStatus.Pending))
        self.audit.log(AuditEntity.Match, AuditAction.Create, actor_id, f"match_id={match.id}")
        return match

    def update(self, match_id: int, data: MatchUpdate, actor_id: int) -> Match:
        match = self.get_by_id(match_id)
        tournament = self._get_tournament_or_404(match.tournament_id)
        require_active_tournament(tournament)

        update_data = data.model_dump(exclude_unset=True)
        goals_home = match.goals_home or 0
        goals_away = match.goals_away or 0
        is_draw = goals_home == goals_away

        if "round" in update_data and update_data["round"] is not None and update_data["round"] != match.round:
            new_round: MatchRound = update_data["round"]
            self._validate_round_dependencies(match.tournament_id, new_round)
            limit = self._max_matches_for_round(new_round)
            if limit is not None:
                current = len(self.repo.get_by_tournament_and_round(match.tournament_id, new_round))
                if current >= limit:
                    raise HTTPException(
                        status_code=400,
                        detail=f"No se pueden crear más de {limit} partidos en la ronda {new_round.value}",
                    )

        # Finished matches are immutable
        if match.status == MatchStatus.Finished and update_data:
            raise HTTPException(status_code=400, detail="No se puede modificar un partido finalizado")

        # When match is Playing, only allow changing status (to Penalties or Finished)
        if match.status == MatchStatus.Playing:
            extra_keys = set(update_data.keys()) - {"status"}
            if extra_keys:
                raise HTTPException(status_code=400, detail="No se puede modificar la información del partido en juego")
            if "status" in update_data and update_data["status"] == MatchStatus.Playing:
                update_data.pop("status", None)
            if "status" in update_data and update_data["status"] not in (MatchStatus.Penalties, MatchStatus.Finished):
                raise HTTPException(status_code=400, detail="Un partido en juego solo puede pasar a 'Penaltis' o 'Finalizado'")
            if "status" in update_data and update_data["status"] == MatchStatus.Penalties and not is_draw:
                raise HTTPException(status_code=400, detail="Solo se puede pasar a 'Penaltis' si el marcador está empatado")
            if "status" in update_data and update_data["status"] == MatchStatus.Finished and is_draw:
                raise HTTPException(status_code=400, detail="Si el marcador está empatado, el partido debe pasar a 'Penaltis'")

        # When match is Penalties, only allow changing status to Finished
        if match.status == MatchStatus.Penalties:
            extra_keys = set(update_data.keys()) - {"status"}
            if extra_keys:
                raise HTTPException(status_code=400, detail="No se puede modificar la información del partido durante los penaltis")
            if "status" in update_data and update_data["status"] == MatchStatus.Penalties:
                update_data.pop("status", None)
            if "status" in update_data and update_data["status"] != MatchStatus.Finished:
                raise HTTPException(status_code=400, detail="Un partido en penaltis solo puede pasar a 'Finalizado'")
            if "status" in update_data and is_draw:
                if match.pen_home is None or match.pen_away is None:
                    raise HTTPException(status_code=400, detail="La tanda de penaltis no está registrada")
                if match.pen_home == match.pen_away:
                    raise HTTPException(status_code=400, detail="La tanda de penaltis no puede finalizar en empate")

        if not update_data:
            return match

        if "goals_home" in update_data or "goals_away" in update_data:
            raise HTTPException(status_code=400, detail="El marcador se actualiza automáticamente por eventos")

        if "pen_home" in update_data or "pen_away" in update_data:
            raise HTTPException(status_code=400, detail="Los penaltis se actualizan automáticamente por eventos")

        if "team_home_id" in update_data:
            if match.team_home_id is not None:
                # Once set, can't change or clear
                if update_data["team_home_id"] != match.team_home_id:
                    raise HTTPException(status_code=400, detail="No se puede modificar el equipo local una vez asignado")
            else:
                if update_data["team_home_id"] is None:
                    raise HTTPException(status_code=400, detail="El equipo local no puede ser nulo")
                team = self.team_repo.get_by_id(update_data["team_home_id"])
                if not team or team.tournament_id != match.tournament_id:
                    raise HTTPException(status_code=400, detail="El equipo local no pertenece al torneo del partido")
        if "team_away_id" in update_data:
            if match.team_away_id is not None:
                if update_data["team_away_id"] != match.team_away_id:
                    raise HTTPException(status_code=400, detail="No se puede modificar el equipo visitante una vez asignado")
            else:
                if update_data["team_away_id"] is None:
                    raise HTTPException(status_code=400, detail="El equipo visitante no puede ser nulo")
                team = self.team_repo.get_by_id(update_data["team_away_id"])
                if not team or team.tournament_id != match.tournament_id:
                    raise HTTPException(status_code=400, detail="El equipo visitante no pertenece al torneo del partido")

        home_id = update_data.get("team_home_id", match.team_home_id)
        away_id = update_data.get("team_away_id", match.team_away_id)
        if home_id is not None and away_id is not None and home_id == away_id:
            raise HTTPException(status_code=400, detail="Equipo local y visitante no pueden ser el mismo")

        # Status transitions: Pending can only move to Playing (not directly to Finished)
        if "status" in update_data and match.status == MatchStatus.Pending and update_data["status"] == MatchStatus.Finished:
            raise HTTPException(status_code=400, detail="Un partido pendiente solo puede pasar a 'En juego'")
        if "status" in update_data and match.status == MatchStatus.Pending and update_data["status"] not in (MatchStatus.Pending, MatchStatus.Playing):
            raise HTTPException(status_code=400, detail="Transición de estado no permitida")

        # If status is moved to Playing, reset score to 0-0
        if "status" in update_data and update_data["status"] == MatchStatus.Playing and match.status != MatchStatus.Playing:
            # Validate required match data + lineups before starting
            field_value = update_data.get("field", match.field)
            datetime_value = update_data.get("datetime", match.datetime)
            round_value = update_data.get("round", match.round)
            tournament_value = match.tournament_id

            missing = []
            if tournament_value is None:
                missing.append("torneo")
            if round_value is None:
                missing.append("ronda")
            if home_id is None:
                missing.append("equipo local")
            if away_id is None:
                missing.append("equipo visitante")
            if field_value is None or (isinstance(field_value, str) and not field_value.strip()):
                missing.append("campo")
            if datetime_value is None:
                missing.append("fecha y hora")

            if missing:
                raise HTTPException(
                    status_code=400,
                    detail="No se puede pasar a 'En juego' si faltan: " + ", ".join(missing),
                )

            home_lineups = self.lineup_repo.get_by_match_and_team(match.id, home_id)
            away_lineups = self.lineup_repo.get_by_match_and_team(match.id, away_id)
            if not home_lineups or not away_lineups:
                raise HTTPException(
                    status_code=400,
                    detail="No se puede pasar a 'En juego' sin alineaciones de ambos equipos",
                )

            match.goals_home = 0
            match.goals_away = 0
            match.pen_home = None
            match.pen_away = None

        # If status is moved to Penalties, initialize penalties score if needed
        if "status" in update_data and update_data["status"] == MatchStatus.Penalties and match.status != MatchStatus.Penalties:
            if match.pen_home is None:
                match.pen_home = 0
            if match.pen_away is None:
                match.pen_away = 0

        updated = self.repo.update(match, MatchUpdate(**update_data))
        self.audit.log(AuditEntity.Match, AuditAction.Update, actor_id, f"match_id={match_id}")
        return updated

    def delete(self, match_id: int, actor_id: int) -> None:
        match = self.get_by_id(match_id)
        self.repo.delete(match)
        self.audit.log(AuditEntity.Match, AuditAction.Delete, actor_id, f"match_id={match_id}")
