# 🗄️ Estructura Base de Datos
Base de datos en PostgreSQL.
Modelos SQLAlchemy2.0.
Migraciones con Alembic.

---

## users (usuario de la aplicación)

- **id** (int, autogenerado, PK) → identificador del usuario  
- **username** (string, único, obligatorio) → nombre de usuario  
- **email** (string, único, obligatorio) → email del usuario  
- **password_hash** (string, obligatorio) → contraseña hasheada  
- **role** (enum, obligatorio) →  
  - admin  
  - org  
  - user  
- **created_at** (datetime, obligatorio) → fecha de creación  
- **updated_at** (datetime, opcional) → fecha de actualización  

---

## tournaments

- **id** (int, autogenerado, PK) → identificador del torneo  
- **name** (string, único, obligatorio) → nombre del torneo  
- **place** (string, obligatorio) → lugar del torneo
- **date_ini** (datetime, obligatorio) → fecha de inicio del torneo  
- **date_end** (datetime, obligatorio) → fecha de finalización del torneo  
- **created_at** (datetime, obligatorio) → fecha de creación  
- **updated_at** (datetime, opcional) → fecha de actualización  

---

## user_tournaments

- **id** (int, autogenerado, PK)  
- **user_id** (int, obligatorio, FK a users)  
- **tournament_id** (int, obligatorio, FK a tournaments)  
- **created_at** (datetime, obligatorio)  
- **updated_at** (datetime, opcional)  

### Restricciones
- `uq_tournament_user` → un usuario no puede seguir el mismo torneo varias veces

---

## teams

- **id** (int, autogenerado, PK) → identificador del equipo  
- **name** (string, obligatorio) → nombre del equipo  
- **group** (string, obligatorio) → grupo/clase (ej. “2º DAM”, “Profesores”)  
- **tournament_id** (int, obligatorio, FK a tournaments)  
- **kit_color** (string, obligatorio) → color de la equipación  
- **logo_url** (string, opcional) → escudo  
- **created_at** (datetime, obligatorio)  
- **updated_at** (datetime, opcional)  

### Restricciones
- `uq_tournament_team_name` → solo puede existir 1 equipo con el mismo nombre en un torneo  

---

## players

- **id** (int, autogenerado, PK)  
- **name** (string, obligatorio)  
- **dni** (string, único, obligatorio)  
- **created_at** (datetime, obligatorio)  
- **updated_at** (datetime, opcional)  

---

## player_teams

- **id** (int, autogenerado, PK)  
- **player_id** (int, obligatorio, FK a players)  
- **team_id** (int, obligatorio, FK a teams)  
- **number** (int, obligatorio) → dorsal  
- **created_at** (datetime, obligatorio)  
- **updated_at** (datetime, opcional)  

### Restricciones
- `uq_team_number` → solo 1 jugador con el mismo dorsal en un equipo  
- `uq_team_player` → solo se puede registrar una vez un jugador en un equipo  

---

## matches

- **id** (int, autogenerado, PK)  
- **team_home_id** (int, opcional, FK a teams)  
- **team_away_id** (int, opcional, FK a teams)  
- **goals_home** (int, opcional)  
- **goals_away** (int, opcional)  
- **datetime** (datetime, opcional)  
- **field** (string, opcional)  
- **tournament_id** (int, obligatorio, FK a tournaments)  
- **round** (enum, obligatorio):  
  - Quarterfinal  
  - Semifinal  
  - Final  
- **status** (enum, obligatorio):  
  - Pending  
  - Playing  
  - Finished  
- **created_at** (datetime, obligatorio)  
- **updated_at** (datetime, opcional)  

---

## lineups

- **id** (int, autogenerado, PK)  
- **match_id** (int, obligatorio, FK a matches)  
- **team_id** (int, obligatorio, FK a teams)  
- **player_id** (int, obligatorio, FK a players)  
- **role** (enum, obligatorio):  
  - Starter  
  - Bench  
- **created_at** (datetime, obligatorio)  
- **updated_at** (datetime, opcional)  

---

## events

- **id** (int, autogenerado, PK)  
- **match_id** (int, obligatorio, FK a matches)  
- **team_id** (int, obligatorio, FK a teams)  
- **player_id** (int, obligatorio, FK a players)  
- **event_type** (enum, obligatorio):  
  - Goal 
  - Owngoal 
  - Yellow  
  - YellowX2  
  - Red  
- **minute** (int, opcional)  
- **description** (string, opcional)  
- **created_at** (datetime, obligatorio)  
- **updated_at** (datetime, opcional)  

## audit_logs

- **id** (int, autogenerado, PK)  
- **entity** (enum, obligatorio)  
    - User
    - Tournament
    - User_tournament
    - Team
    - Player
    - Player_team
    - Match
    - Event
    - Lineup
- **action** (enum, obligatorio)  
    - Create
    - Update
    - Delete
- **user_id** (int, obligatorio, FK a users)  
- **details** (string, opcional):    
- **created_at** (datetime, obligatorio)  
