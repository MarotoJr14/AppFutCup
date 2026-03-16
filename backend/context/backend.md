# Estructura de backend/app
backend
+---app
|    |   main.py
|    |   __init__.py
|    |
|    +---api
|    |   \---v1
|    |       |   api.py
|    |       |   deps.py
|    |       |   security.py
|    |       |
|    |       +---routes
|    |           auth.py
|    |           events.py
|    |           lineups.py
|    |           matches.py
|    |           players.py
|    |           player_teams.py
|    |           teams.py
|    |           tournaments.py
|    |           user_tournaments.py
|    |           users.py
|    |
|    +---core
|    |   config.py
|    |   security.py
|    |   __init__.py
|    |
|    +---db
|    |   base.py
|    |   deps.py
|    |   session.py
|    |   __init__.py
|    |
|    +---models
|    |   audit_log.py
|    |   enums.py
|    |   event.py
|    |   lineup.py
|    |   match.py
|    |   player.py
|    |   player_team.py
|    |   team.py
|    |   tournament.py
|    |   user_tournament.py
|    |   user.py
|    |   __init__.py
|    |
|    +---repositories
|    |   event_repository.py
|    |   lineup_repository.py
|    |   match_repository.py
|    |   player_repository.py
|    |   player_team_repository.py
|    |   team_repository.py
|    |   tournament_repository.py
|    |   user_tournament_repository.py
|    |   user_repository.py
|    |   __init__.py
|    |
|    +---schemas
|    |   auth_schema.py
|    |   event_schema.py
|    |   lineup_schema.py
|    |   match_schema.py
|    |   player_schema.py
|    |   player_team_schema.py
|    |   team_schema.py
|    |   tournament_schema.py
|    |   user_tournament_schema.py
|    |   user_schema.py
|    |   __init__.py
|    |
|    +---services
|    |   auth_service.py
|    |   event_service.py
|    |   lineup_service.py
|    |   match_service.py
|    |   player_service.py
|    |   player_team_service.py
|    |   team_service.py
|    |   tournament_service.py
|    |   user_tournament_service.py
|    |   user_service.py
|    |   __init__.py
|    |
|    +---utils
|    |   __init__.py
|
.env
.gitignore
alembic.ini
docker-compose.yml
Dockerfile
entrypoint.sh
README.MD
requirements.txt

---

# Endpoints API
- CRUD de cada tabla para una plataforma de aministradores
    - Ahora la plataforma no es importante, solo dejar listos los endpoints
- Los necesarios para el funcionamiento correcto de la aplicación

---

# Notas
- BD y backend metidos en contenedores, con docker (Dockerfile, docker-compose.yml, entrypoint.sh)
- Uso de Swagger para la API
