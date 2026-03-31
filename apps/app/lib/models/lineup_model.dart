class LineupModel {
  final int id;
  final int matchId;
  final int teamId;
  final int playerId;
  final String role;

  LineupModel({
    required this.id, required this.matchId, required this.teamId,
    required this.playerId, required this.role,
  });

  factory LineupModel.fromJson(Map<String, dynamic> json) => LineupModel(
    id: json['id'],
    matchId: json['match_id'],
    teamId: json['team_id'],
    playerId: json['player_id'],
    role: json['role'],
  );
}
