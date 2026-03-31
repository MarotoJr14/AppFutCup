import enum


class UserRole(str, enum.Enum):
    admin = "admin"
    org = "org"
    user = "user"


class MatchRound(str, enum.Enum):
    RoundOf16 = "RoundOf16"
    Quarterfinal = "Quarterfinal"
    Semifinal = "Semifinal"
    Final = "Final"


class MatchStatus(str, enum.Enum):
    Pending = "Pending"
    Playing = "Playing"
    Penalties = "Penalties"
    Finished = "Finished"


class LineupRole(str, enum.Enum):
    Starter = "Starter"
    Bench = "Bench"


class EventType(str, enum.Enum):
    Goal = "Goal"
    Owngoal = "Owngoal"
    Yellow = "Yellow"
    YellowX2 = "YellowX2"
    Red = "Red"
    PenaltyScored = "PenaltyScored"
    PenaltyMissed = "PenaltyMissed"


class AuditEntity(str, enum.Enum):
    User = "User"
    Tournament = "Tournament"
    User_tournament = "User_tournament"
    Team = "Team"
    Player = "Player"
    Player_team = "Player_team"
    Match = "Match"
    Event = "Event"
    Lineup = "Lineup"


class AuditAction(str, enum.Enum):
    Create = "Create"
    Update = "Update"
    Delete = "Delete"
