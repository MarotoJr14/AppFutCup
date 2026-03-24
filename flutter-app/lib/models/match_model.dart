class MatchModel {
  final int id;
  final int? teamHomeId;
  final int? teamAwayId;
  final int? goalsHome;
  final int? goalsAway;
  final DateTime? matchDatetime;
  final String? field;
  final int tournamentId;
  final String round;
  final String status;

  MatchModel({
    required this.id, this.teamHomeId, this.teamAwayId,
    this.goalsHome, this.goalsAway, this.matchDatetime,
    this.field, required this.tournamentId,
    required this.round, required this.status,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) => MatchModel(
    id: json['id'],
    teamHomeId: json['team_home_id'],
    teamAwayId: json['team_away_id'],
    goalsHome: json['goals_home'],
    goalsAway: json['goals_away'],
    matchDatetime: json['datetime'] != null ? DateTime.parse(json['datetime']) : null,
    field: json['field'],
    tournamentId: json['tournament_id'],
    round: json['round'],
    status: json['status'],
  );
}
