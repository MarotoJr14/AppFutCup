import 'dart:convert';

class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;

  UserModel({required this.id, required this.username, required this.email, required this.role});

  bool get isOrg => role == 'org';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    username: json['username'],
    email: json['email'],
    role: json['role'],
  );

  Map<String, dynamic> toJson() => {'id': id, 'username': username, 'email': email, 'role': role};

  String toJsonString() => jsonEncode(toJson());
  factory UserModel.fromJsonString(String s) => UserModel.fromJson(jsonDecode(s));
}
