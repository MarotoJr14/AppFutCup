class TeamModel {
  final int id;
  final String name;
  final String group;
  final int tournamentId;
  final String kitColor;
  final String? logoUrl;

  TeamModel({
    required this.id, required this.name, required this.group,
    required this.tournamentId, required this.kitColor, this.logoUrl,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) => TeamModel(
    id: json['id'],
    name: json['name'],
    group: json['group'],
    tournamentId: json['tournament_id'],
    kitColor: json['kit_color'],
    logoUrl: json['logo_url'],
  );
}
