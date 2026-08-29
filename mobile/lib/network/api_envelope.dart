/// Helpers for the `{message, data}` envelope every resource controller on the
/// backend returns.
///
/// ---------------------------------------------------------------------------
/// `AccountController`, `CategoryController`, `TransactionController` and
/// `BudgetController` all answer with:
///
///     { "message": "...", "data": <object|array> }
///
/// `AuthController` does **not** — it returns a flat body
/// (`{message, access_token, token_type, user}`), which is why `AuthRepo`
/// parses its responses by hand and does not use these helpers.
///
/// Both functions **throw a [Failure]** rather than returning an `Either`. That
/// is deliberate: every repository method already wraps its body in the
/// `try { ... } on Failure catch (e) { return Left(e); }` shape used by
/// `NotificationsRepo`, so throwing lets the failure surface through the catch
/// the caller already has, instead of forcing an `Either` unwrap at nine call
/// sites.
///
/// `DioClient` sets `ResponseType.plain`, so `response.data` is a `String` and
/// must be decoded before it can be indexed.
/// ---------------------------------------------------------------------------
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:family_expense_management/network/failure.dart';

/// The `data` field of a successful response, as a list of JSON objects.
///
/// Throws a [Failure] for any non-2xx status, and for a body whose `data` is
/// not a list — which would otherwise surface as a confusing cast error deep
/// inside a `map`.
List<Map<String, dynamic>> unwrapList(Response response) {
  final data = _unwrapData(response);

  if (data is! List) throw ServerFailure();

  return [
    for (final item in data)
      if (item is Map<String, dynamic>) item,
  ];
}

/// The `data` field of a successful response, as a single JSON object.
Map<String, dynamic> unwrapObject(Response response) {
  final data = _unwrapData(response);

  if (data is! Map<String, dynamic>) throw ServerFailure();

  return data;
}

/// Asserts a successful response without reading its `data`.
///
/// For the delete endpoints, which answer `{"message": "..."}` and carry no
/// `data` field at all — [unwrapObject] would reject that as a malformed body.
void ensureSuccess(Response response) => _unwrapData(response);

/// Shared status handling.
///
/// The status ladder mirrors `NotificationsRepo` exactly, with one addition:
/// 401 is called out separately. Laravel's `auth:sanctum` middleware answers
/// `{"message":"Unauthenticated."}` in English regardless of the `X-Lang`
/// header, and showing that raw string to the user is worse than the app's own
/// localised message.
dynamic _unwrapData(Response response) {
  final int? code = response.statusCode;

  if (code == 200 || code == 201) {
    final decoded = json.decode(response.data);
    if (decoded is! Map<String, dynamic>) throw ServerFailure();
    return decoded['data'];
  }

  // Session expired, or the token was revoked — `AuthController::login` deletes
  // every previous token, so signing in elsewhere invalidates this one.
  if (code == 401) throw ResultFailure('unauthenticated'.tr());

  if (code == 500) throw ServerFailure();

  // 403 (the child's spending limit), 404 and 422 (validation) all carry a
  // server-authored, already-localised `message` worth showing verbatim.
  try {
    final decoded = json.decode(response.data);
    if (decoded is Map && decoded['message'] is String) {
      throw ResultFailure(decoded['message'] as String);
    }
  } on FormatException {
    // A non-JSON error body — an HTML stack trace from a debug-mode crash, for
    // instance. Falls through to the generic failure below rather than
    // rendering markup inside a snackbar.
  }

  throw ServerFailure();
}
