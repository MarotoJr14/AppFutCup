# FutCup API (backend) — `backend/`

Esta carpeta contiene el **backend** del proyecto FutCup: una API REST construida con **FastAPI**, persistencia con **SQLAlchemy** y base de datos **PostgreSQL**. Sirve de fuente de verdad para:

- Usuarios y autenticación (JWT Bearer)
- Torneos y seguimiento de torneos
- Equipos, jugadores y relación jugador–equipo
- Partidos, alineaciones y eventos
- Auditoría de acciones (audit logs)

La API expone documentación interactiva:
- Swagger: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Stack y componentes

- **FastAPI** (`backend/app/main.py`) + CORS abierto en dev
- **SQLAlchemy** (`backend/app/db/*`) con engine por `DATABASE_URL`
- **Alembic** (`backend/alembic/*`) para migraciones
- **Auth JWT** (`backend/app/core/security.py`) con `Authorization: Bearer <token>`
- Patrón típico **routes → services → repositories → models**

## Estructura de carpetas (resumen)

- `backend/app/main.py`: instancia de FastAPI + middleware CORS + router principal
- `backend/app/api/v1/`: API versionada con prefijo `/api/v1`
  - `backend/app/api/v1/api.py`: agrega rutas
  - `backend/app/api/v1/routes/*`: endpoints por recurso
  - `backend/app/api/v1/deps.py`: dependencias comunes (auth/roles)
- `backend/app/models/`: modelos SQLAlchemy (DB)
- `backend/app/schemas/`: esquemas Pydantic (entrada/salida)
- `backend/app/repositories/`: acceso a DB (CRUD)
- `backend/app/services/`: lógica de negocio (validaciones + auditoría)
- `backend/app/db/`: engine, sesión y dependencias de DB
- `backend/alembic/`: migraciones
- `backend/scripts/`: scripts utilitarios (seed)

## Configuración (variables de entorno)

La configuración se carga desde `backend/.env` (la ruta se resuelve relativa a `backend/`, ver `backend/app/core/config.py`).

Variables principales:
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `DATABASE_URL` (SQLAlchemy): `postgresql://user:pass@host:5432/db`
- `SECRET_KEY` (firma JWT), `ALGORITHM` (p. ej. `HS256`)
- `ACCESS_TOKEN_EXPIRE_MINUTES`

Notas:
- En **Docker Compose**, el backend usa una `DATABASE_URL` apuntando al servicio `db` (no `localhost`).
- Para producción, **no** uses el `.env` de ejemplo sin cambiar `SECRET_KEY` y credenciales.

## Ejecutar con Docker (recomendado)

Desde `backend/`:

```bash
docker compose up --build
```

Servicios:
- PostgreSQL: `localhost:5432`
- API: `http://localhost:8000`

Comportamiento al arrancar:
- Se ejecutan migraciones automáticamente: `alembic upgrade head` (ver `backend/entrypoint.sh`)
- Uvicorn se levanta con `--reload` para desarrollo (ver `backend/entrypoint.sh`)

## Ejecutar en local (sin Docker)

Requisitos:
- Python 3.12
- PostgreSQL 16

1) Crear venv e instalar dependencias:

```bash
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

2) Configurar `.env` (o exportar variables) y asegurarte de que Postgres está accesible.

3) Ejecutar migraciones:

```bash
alembic upgrade head
```

4) Levantar API:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## API: versión, rutas y roles

Prefijo global: `/api/v1` (ver `backend/app/api/v1/api.py`).

Recursos principales (orientativo):
- Auth: `/auth/register`, `/auth/login`
- Users: `/users`, `/users/me`
- Tournaments: `/tournaments`
- User tournaments (seguimiento): `/user-tournaments` (incluye follow/unfollow)
- Teams: `/teams`
- Players: `/players`
- Player–Teams: `/player-teams`
- Matches: `/matches`
- Lineups: `/lineups`
- Events: `/events`
- Player stats: `/player-stats`
- Audit logs: `/audit-logs`

Autenticación:
- La mayoría de endpoints requieren `Authorization: Bearer <token>` (ver `backend/app/api/v1/deps.py`).

Roles:
- `user`: acceso de lectura a recursos protegidos
- `org`: puede crear/editar varios recursos de torneo (según endpoint)
- `admin`: permisos extendidos (incluye borrados y auditoría)

Las protecciones se aplican con dependencias tipo `require_org` / `require_admin` (ver `backend/app/api/v1/deps.py`).

## Base de datos y migraciones (Alembic)

- Alembic detecta modelos importando `app.models` (ver `backend/alembic/env.py`).
- Alembic usa `DATABASE_URL` si está presente; si no, utiliza `sqlalchemy.url` de `backend/alembic.ini`.

Comandos típicos:

```bash
alembic revision --autogenerate -m "descripcion"
alembic upgrade head
alembic downgrade -1
```

## Seed / datos de ejemplo

Scripts en `backend/scripts/`:

- `seed_users.py`
  - Crea usuarios de prueba mediante `UserRepository` (la contraseña se **hashea**).
  - Incluye un usuario `admin` para entrar al panel admin.

- `seed_db.py`
  - Genera datos de ejemplo (torneo/equipos/jugadores/partidos).
  - Ojo: en ese script se insertan `password_hash="hashed_*"` en los usuarios iniciales (no es válido para login).

Local:

```bash
python scripts/seed_users.py
python scripts/seed_db.py
```

En Docker:

```bash
docker exec -it futcup_backend python scripts/seed_users.py
docker exec -it futcup_backend python scripts/seed_db.py
```

## Desarrollo: cómo añadir un recurso nuevo

Flujo recomendado (consistente con el repo):
1) Modelo SQLAlchemy en `backend/app/models/`
2) Esquemas Pydantic en `backend/app/schemas/`
3) Repositorio (CRUD) en `backend/app/repositories/`
4) Servicio (validaciones/auditoría) en `backend/app/services/`
5) Ruta FastAPI en `backend/app/api/v1/routes/` y registrar en `backend/app/api/v1/api.py`
6) Migración Alembic

## Troubleshooting

- **Acentos “rotos”** en terminal/editor: asegúrate de trabajar en UTF-8 (en Windows, el encoding de consola/archivos puede variar).
- **401 Token inválido o expirado**: vuelve a loguearte; el backend valida JWT y el frontend limpia sesión al recibir 401.
- **Con Docker, Postgres no responde**: revisa healthcheck del servicio `db` en `backend/docker-compose.yml` y las credenciales del `.env`.
