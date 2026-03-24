class EventModel {
  final int id;
  final int matchId;
  final int teamId;
  final int playerId;
  final String eventType;
  final int? minute;
  final String? description;

  EventModel({
    required this.id, required this.matchId, required this.teamId,
    required this.playerId, required this.eventType,
    this.minute, this.description,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
    id: json['id'],
    matchId: json['match_id'],
    teamId: json['team_id'],
    playerId: json['player_id'],
    eventType: json['event_type'],
    minute: json['minute'],
    description: json['description'],
  );
}
