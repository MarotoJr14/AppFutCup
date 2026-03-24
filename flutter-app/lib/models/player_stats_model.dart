class PlayerStatsModel {
  final int playerId;
  final String playerName;
  final String teamName;
  final int number;
  final int matchesStarter;
  final int matchesBench;
  final int goals;
  final double goalsPerMatch;
  final int yellowCards;
  final int doubleYellows;
  final int redCards;

  PlayerStatsModel({
    required this.playerId, required this.playerName, required this.teamName,
    required this.number, required this.matchesStarter, required this.matchesBench,
    required this.goals, required this.goalsPerMatch,
    required this.yellowCards, required this.doubleYellows, required this.redCards,
  });

  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) => PlayerStatsModel(
    playerId: json['player_id'],
    playerName: json['player_name'],
    teamName: json['team_name'],
    number: json['number'],
    matchesStarter: json['matches_starter'],
    matchesBench: json['matches_bench'],
    goals: json['goals'],
    goalsPerMatch: (json['goals_per_match'] as num).toDouble(),
    yellowCards: json['yellow_cards'],
    doubleYellows: json['double_yellows'],
    redCards: json['red_cards'],
  );
}
