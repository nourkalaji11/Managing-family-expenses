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

  /// What this person has spent against their ceiling, and what is left.
  ///
  /// Sent by `GET /users` only — null everywhere else, including on the user
  /// returned by login. A parent opens the family screen to see what has been
  /// used, not merely what is permitted.
  ///
  /// [remaining] is null when [spendingLimit] is: "no ceiling" and "nothing
  /// left" are opposite states and one number cannot carry both.
  num? spent;
  num? remaining;

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
    this.spent,
    this.remaining,
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
    // Laravel serialises DECIMAL as a string ("300.00"). The column is
    // nullable, and null is meaningful: no ceiling has been set. It is NOT the
    // same as 0, which is a ceiling a parent set deliberately to freeze
    // spending — the server stopped conflating the two.
    spendingLimit: _toNum(json["spending_limit"]),
    spent: _toNum(json["spent"]),
    remaining: _toNum(json["remaining"]),
  );

  /// Returns a copy with the given fields replaced.
  ///
  /// [token] is carried over rather than re-supplied: `PUT /profile` answers
  /// with the user row alone and issues no new token, so a naive replace would
  /// silently sign the user out after an edit.
  /// Sentinel for [copyWith], so that clearing a ceiling is expressible.
  ///
  /// `spendingLimit: null` in a `??`-based copyWith means "keep the old one",
  /// which would make removing a ceiling impossible — and removing one is a
  /// thing a parent has to be able to do.
  static const Object _unset = Object();

  User copyWith({
    String? name,
    String? email,
    String? role,
    Object? spendingLimit = _unset,
    num? spent,
    num? remaining,
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
    spendingLimit: identical(spendingLimit, _unset)
        ? this.spendingLimit
        : spendingLimit as num?,
    spent: spent ?? this.spent,
    remaining: remaining ?? this.remaining,
  );

  /// True when a parent has set a ceiling. A ceiling of 0 counts: that is a
  /// deliberate freeze, not an absence.
  bool get hasSpendingLimit => spendingLimit != null;
}

/// Laravel returns `DECIMAL` columns as strings.
num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
