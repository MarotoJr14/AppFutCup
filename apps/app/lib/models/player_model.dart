class PlayerModel {
  final int id;
  final String name;
  final String dni;

  PlayerModel({required this.id, required this.name, required this.dni});

  factory PlayerModel.fromJson(Map<String, dynamic> json) => PlayerModel(
    id: json['id'],
    name: json['name'],
    dni: json['dni'],
  );
}
