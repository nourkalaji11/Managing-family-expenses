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

  // ---------------------------------------------------------------------------
  // Family Expenses. APPEND-ONLY: nothing above this line was renamed, because
  // the auth flow already depends on those fields.
  // ---------------------------------------------------------------------------

  /// The `users.role` column: `parent` or `member`.
  ///
  /// Rows created before the roles were unified may still read `admin`, which
  /// the server treats as a parent — see `isParent`. Never trust this field for
  /// authorisation: it decides what the UI *offers*, and the server decides
  /// what actually goes through.
  String? role;

  /// The `users.spending_limit` column. Meaningful only for a member; a parent
  /// is not capped, and the server refuses to set one on them.
  num? spendingLimit;

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
    this.role,
    this.spendingLimit,
  });

  /// True when this user may manage the family: set spending limits, see every
  /// member, and read the family-wide dashboard.
  ///
  /// Accepts both spellings for the same reason the server does — see
  /// `User::PARENT_ROLES` in the backend.
  bool get isParent {
    final String r = (role ?? '').toLowerCase();
    return r == 'parent' || r == 'admin';
  }

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
    role: json["role"],
    // Laravel serialises DECIMAL as a string ("300.00"); the column is NOT NULL
    // with a 0 default, so a null here only means the payload omitted it.
    spendingLimit: _toNum(json["spending_limit"]),
  );

  /// Returns a copy with the given fields replaced.
  ///
  /// [token] is carried over rather than re-supplied: `PUT /profile` answers
  /// with the user row alone and issues no new token, so a naive replace would
  /// silently sign the user out after an edit.
  User copyWith({
    String? name,
    String? email,
    String? role,
    num? spendingLimit,
  }) => User(
    id: id,
    name: name ?? this.name,
    username: username,
    email: email ?? this.email,
    phone: phone,
    about: about,
    title: title,
    job: job,
    gender: gender,
    nationality: nationality,
    birthDate: birthDate,
    token: token,
    role: role ?? this.role,
    spendingLimit: spendingLimit ?? this.spendingLimit,
  );
}

/// Laravel returns `DECIMAL` columns as strings.
num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
