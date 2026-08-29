// To parse this JSON data, do
//
//     final user = userFromJson(jsonString);

import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

class User {
  int? id;
  String? name;
  String? username;
  String? email;
  String? phone;
  String? about;
  String? title;
  String? job;
  String? gender;
  String? nationality;
  DateTime? birthDate;
  String? token;

  User({
    this.id,
    this.name,
    this.username,
    this.email,
    this.phone,
    this.about,
    this.title,
    this.job,
    this.gender,
    this.nationality,
    this.birthDate,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    name: json["name"],
    username: json['username'],
    email: json["email"],
    phone: json["phone"],
    about: json['about'],
    title: json['title'],
    job: json['job'],
    gender: json['gender'],
    nationality: json['nationality'],
    birthDate: json["birth_date"] == null
        ? null
        : DateTime.parse(json["birth_date"]),
  );
}
