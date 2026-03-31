class TournamentModel {
  final int id;
  final String name;
  final String place;
  final DateTime dateIni;
  final DateTime dateEnd;
  final bool isActive;

  TournamentModel({
    required this.id, required this.name, required this.place,
    required this.dateIni, required this.dateEnd, required this.isActive,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) => TournamentModel(
    id: json['id'],
    name: json['name'],
    place: json['place'],
    dateIni: DateTime.parse(json['date_ini']),
    dateEnd: DateTime.parse(json['date_end']),
    isActive: json['is_active'] ?? false,
  );
}
