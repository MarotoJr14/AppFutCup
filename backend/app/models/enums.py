import enum

class UserRole(enum.Enum):
    admin = "admin"
    org = "org"
    user = "user"

class MatchStatus(enum.Enum):
    pending = "pending"
    playing = "playing"
    finished = "finished"
    
class MatchRound(enum.Enum):
    quarterfinal = "quarterfinal"
    semifinal = "semifinal"
    final = "final"

class LineupRole(enum.Enum):
    starter = "starter"
    bench = "bench"

class EventType(enum.Enum):
    goal = "goal"
    owngoal = "owngoal"
    yellow = "yellow"
    red = "red"
    yellowX2 = "yellowX2"

class EntityType(enum.Enum):
    user = "user"
    tournament = "tournament"
    user_tournament = "user_tournament"
    team = "team"
    player = "player"
    player_team = "player_team"
    match = "match"
    event = "event"
    lineup = "lineup"
    
class ActionType(enum.Enum):
    create = "create"
    update = "update"
    delete = "delete"