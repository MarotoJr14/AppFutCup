class PlayerTeamModel {
  final int id;
  final int playerId;
  final int teamId;
  final int number;

  PlayerTeamModel({required this.id, required this.playerId, required this.teamId, required this.number});

  factory PlayerTeamModel.fromJson(Map<String, dynamic> json) => PlayerTeamModel(
    id: json['id'],
    playerId: json['player_id'],
    teamId: json['team_id'],
    number: json['number'],
  );
}
