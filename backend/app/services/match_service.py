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

    def _round_index(self, round: MatchRound) -> int:
        order = {
            MatchRound.RoundOf16: 0,
            MatchRound.Quarterfinal: 1,
            MatchRound.Semifinal: 2,
            MatchRound.Final: 3,
        }
        return order[round]

    def _max_matches_for_round(self, round: MatchRound) -> int | None:
        limits = {
            MatchRound.RoundOf16: 8,
            MatchRound.Quarterfinal: 4,
            MatchRound.Semifinal: 2,
            MatchRound.Final: 1,
        }
        return limits.get(round)

    def _team_label(self, team_id: int) -> str:
        team = self.team_repo.get_by_id(team_id)
        return f"{team.name} (#{team_id})" if team else f"#{team_id}"

    def _get_winner_loser_ids(self, match: Match) -> tuple[int | None, int | None]:
        if match.status != MatchStatus.Finished:
            return None, None
        if match.team_home_id is None or match.team_away_id is None:
            return None, None
        if match.goals_home is None or match.goals_away is None:
            return None, None

        if match.goals_home > match.goals_away:
            return match.team_home_id, match.team_away_id
        if match.goals_away > match.goals_home:
            return match.team_away_id, match.team_home_id

        if match.pen_home is None or match.pen_away is None:
            return None, None
        if match.pen_home > match.pen_away:
            return match.team_home_id, match.team_away_id
        if match.pen_away > match.pen_home:
            return match.team_away_id, match.team_home_id
        return None, None

    def _validate_unique_team_per_round(
        self,
        *,
        tournament_id: int,
        round: MatchRound,
        team_home_id: int | None,
        team_away_id: int | None,
        exclude_match_id: int | None = None,
    ) -> None:
        if team_home_id is None and team_away_id is None:
            return

        used: dict[int, int] = {}
        for m in self.repo.get_by_tournament_and_round(tournament_id, round):
            if exclude_match_id is not None and m.id == exclude_match_id:
                continue
            if m.team_home_id is not None and m.team_home_id not in used:
                used[m.team_home_id] = m.id
            if m.team_away_id is not None and m.team_away_id not in used:
                used[m.team_away_id] = m.id

        for team_id in (team_home_id, team_away_id):
            if team_id is None:
                continue
            if team_id in used:
                raise HTTPException(
                    status_code=400,
                    detail=(
                        f"El equipo {self._team_label(team_id)} ya está asignado al partido "
                        f"#{used[team_id]} en la ronda {round.value}"
                    ),
                )

    def _validate_not_eliminated_in_previous_rounds(
        self,
        *,
        tournament_id: int,
        round: MatchRound,
        team_home_id: int | None,
        team_away_id: int | None,
        exclude_match_id: int | None = None,
    ) -> None:
        target_idx = self._round_index(round)
        if target_idx <= 0:
            return

        eliminated: dict[int, tuple[MatchRound, int]] = {}
        for m in self.repo.get_by_tournament(tournament_id):
            if exclude_match_id is not None and m.id == exclude_match_id:
                continue
            if self._round_index(m.round) >= target_idx:
                continue
            _, loser_id = self._get_winner_loser_ids(m)
            if loser_id is None:
                continue
            eliminated.setdefault(loser_id, (m.round, m.id))

        for team_id in (team_home_id, team_away_id):
            if team_id is None:
                continue
            if team_id in eliminated:
                lost_round, lost_match_id = eliminated[team_id]
                raise HTTPException(
                    status_code=400,
                    detail=(
                        f"El equipo {self._team_label(team_id)} fue eliminado en {lost_round.value} "
                        f"(partido #{lost_match_id}) y no puede jugar en rondas posteriores"
                    ),
                )

    def _validate_finishing_does_not_conflict_with_future_matches(
        self,
        *,
        match: Match,
        new_round: MatchRound,
        new_status: MatchStatus,
        team_home_id: int | None,
        team_away_id: int | None,
    ) -> None:
        if new_status != MatchStatus.Finished:
            return

        if team_home_id is None or team_away_id is None:
            return
        if match.goals_home is None or match.goals_away is None:
            return

        # Determine loser from current score (goals/penalties updated by events)
        loser_id: int | None = None
        if match.goals_home > match.goals_away:
            loser_id = team_away_id
        elif match.goals_away > match.goals_home:
            loser_id = team_home_id
        else:
            if match.pen_home is None or match.pen_away is None:
                return
            if match.pen_home > match.pen_away:
                loser_id = team_away_id
            elif match.pen_away > match.pen_home:
                loser_id = team_home_id

        if loser_id is None:
            return

        curr_idx = self._round_index(new_round)
        for m in self.repo.get_by_tournament(match.tournament_id):
            if m.id == match.id:
                continue
            if self._round_index(m.round) <= curr_idx:
                continue
            if m.team_home_id == loser_id or m.team_away_id == loser_id:
                raise HTTPException(
                    status_code=400,
                    detail=(
                        f"No se puede finalizar el partido: el equipo {self._team_label(loser_id)} "
                        f"ya está asignado al partido #{m.id} en la ronda {m.round.value}"
                    ),
                )

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

    def get_all(self, skip: int = 0, limit: int | None = None) -> list[Match]:
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

        # Permitir modificar la informaciÃ³n general del partido en cualquier estado (panel admin)
        # Si un atributo ya estÃ¡ relleno, no permitir vaciarlo (solo modificarlo).
        if "team_home_id" in update_data and update_data["team_home_id"] is None and match.team_home_id is not None:
            raise HTTPException(status_code=400, detail="El equipo local no se puede vaciar")
        if "team_away_id" in update_data and update_data["team_away_id"] is None and match.team_away_id is not None:
            raise HTTPException(status_code=400, detail="El equipo visitante no se puede vaciar")
        if "datetime" in update_data and update_data["datetime"] is None and match.datetime is not None:
            raise HTTPException(status_code=400, detail="La fecha y hora no se puede vaciar")
        if "field" in update_data:
            field_value = update_data["field"]
            if (field_value is None or (isinstance(field_value, str) and not field_value.strip())) and match.field is not None:
                raise HTTPException(status_code=400, detail="El campo no se puede vaciar")

        if "status" in update_data and update_data["status"] is None:
            update_data.pop("status", None)
        if match.status == MatchStatus.Finished and "status" in update_data and update_data["status"] != MatchStatus.Finished:
            raise HTTPException(status_code=400, detail="No se puede cambiar el estado de un partido finalizado")

        # When match is Playing, only allow changing status (to Penalties or Finished)
        if match.status == MatchStatus.Playing:
            extra_keys = set()  # permitir editar informaciÃ³n general en cualquier estado
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
            extra_keys = set()  # permitir editar informaciÃ³n general en cualquier estado
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
            if update_data["team_home_id"] is not None:
                team = self.team_repo.get_by_id(update_data["team_home_id"])
                if not team or team.tournament_id != match.tournament_id:
                    raise HTTPException(status_code=400, detail="El equipo local no pertenece al torneo del partido")
        if "team_away_id" in update_data:
            if update_data["team_away_id"] is not None:
                team = self.team_repo.get_by_id(update_data["team_away_id"])
                if not team or team.tournament_id != match.tournament_id:
                    raise HTTPException(status_code=400, detail="El equipo visitante no pertenece al torneo del partido")

        home_id = update_data.get("team_home_id", match.team_home_id)
        away_id = update_data.get("team_away_id", match.team_away_id)
        if home_id is not None and away_id is not None and home_id == away_id:
            raise HTTPException(status_code=400, detail="Equipo local y visitante no pueden ser el mismo")

        next_round: MatchRound = update_data.get("round", match.round)

        if any(k in update_data for k in ("team_home_id", "team_away_id", "round")):
            self._validate_unique_team_per_round(
                tournament_id=match.tournament_id,
                round=next_round,
                team_home_id=home_id,
                team_away_id=away_id,
                exclude_match_id=match.id,
            )
            self._validate_not_eliminated_in_previous_rounds(
                tournament_id=match.tournament_id,
                round=next_round,
                team_home_id=home_id,
                team_away_id=away_id,
                exclude_match_id=match.id,
            )

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

        if "status" in update_data and update_data["status"] == MatchStatus.Finished:
            self._validate_finishing_does_not_conflict_with_future_matches(
                match=match,
                new_round=next_round,
                new_status=MatchStatus.Finished,
                team_home_id=home_id,
                team_away_id=away_id,
            )

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
