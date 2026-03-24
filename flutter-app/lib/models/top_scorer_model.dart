class TopScorerModel {
  final int playerId;
  final String playerName;
  final String teamName;
  final int goals;

  TopScorerModel({required this.playerId, required this.playerName, required this.teamName, required this.goals});

  factory TopScorerModel.fromJson(Map<String, dynamic> json) => TopScorerModel(
    playerId: json['player_id'],
    playerName: json['player_name'],
    teamName: json['team_name'],
    goals: json['goals'],
  );
}
