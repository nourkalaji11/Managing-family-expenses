enum GlobalApiEndpoint {
  /// Root of the API, **without** a trailing slash — `DioClient` builds every
  /// request as `"$_baseUrl/$path"`.
  ///
  /// The path is `/api` with NO version prefix: `routes/api.php` registers
  /// `/register`, `/login`, `/transactions`, ... directly under it.
  ///
  /// Supplied at build time so that a developer's local address never has to be
  /// committed. The compiled-in default stays a placeholder, which means a build
  /// with no `--dart-define` points at nothing and fails loudly, rather than
  /// silently talking to whoever last edited this file.
  ///
  ///   Android emulator → flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
  ///                      (10.0.2.2 is the host's loopback as seen from inside
  ///                      the emulator)
  ///   iOS simulator    → --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
  ///   Physical device  → `--dart-define=API_BASE_URL=http://<your-LAN-ip>:8000/api`
  ///
  /// Plain HTTP also needs the cleartext opt-in already set in
  /// `android/app/src/debug/AndroidManifest.xml` (debug builds only).
  ///
  /// Note: `--dart-define` is baked in at compile time. Changing it requires a
  /// full restart — a hot reload/restart keeps the old value.
  base(
    String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://domain/api',
    ),
  ),

  //splash
  initialSettings("settings/init"),

  //auth
  register("register"),
  login("login"),
  social("social"),
  verifyOTP("verifyOTP"),
  sendOTP("sendOTP"),

  /// `POST`. Revokes the bearer token currently in use, so signing out on this
  /// device does not sign the family out everywhere.
  logout("logout"),

  /// `GET` the signed-in user, `PUT` to edit name, email or password.
  profile("profile"),

  /// `GET`. Family members. A parent gets everyone; a member gets only
  /// themselves — the scoping is the server's, not a filter applied here.
  users("users"),

  /// `PUT`. Sets a member's spending ceiling. Parent-only; answers 403
  /// otherwise, and 422 when the target is itself a parent.
  userLimit("users/{id}/limit"),

  /// `GET`, **paginated** — unlike every other index in this API. Notifications
  /// are the one collection that grows without bound as the family uses the
  /// app. Accepts `page` and `per_page` (capped at 50 server-side).
  notifications("notifications"),
  markAsRead("notifications/{id}/read"),
  markAllAsRead("notifications/read-all"),
  notificationById("notifications/{id}"),

  /// `GET`/`POST`. A transfer is stored as two linked transactions sharing a
  /// `transfer_group_id`; both carry `is_transfer: true`.
  transfers("transfers"),

  /// `DELETE`. Takes the **group id**, not a transaction id: deleting one leg
  /// on its own would leave the other orphaned and a balance wrong.
  transferByGroup("transfers/{group}"),

  // ---------------------------------------------------------------------------
  // Resources. Every one is inside the `auth:sanctum` group in `routes/api.php`,
  // so `DioClient` must have `LocalsApp.user.token` set before calling them —
  // otherwise Laravel answers 401 `{"message":"Unauthenticated."}`.
  //
  // They all answer with the `{message, data}` envelope the resource
  // controllers use. This is NOT the shape `AuthController` returns, which is
  // flat — see `AuthRepo`.
  // ---------------------------------------------------------------------------

  /// `GET`/`POST`. `AccountController::index` orders newest-first.
  accounts("accounts"),

  /// `PUT`/`DELETE`. `DELETE` answers 409, not 204, when the account still
  /// holds transactions.
  accountById("accounts/{id}"),

  /// `GET`/`POST`. `CategoryController::index` orders by name, ascending.
  categories("categories"),

  /// `PUT`/`DELETE`. `DELETE` answers 409 when the category is still referenced
  /// by a transaction or a budget.
  categoryById("categories/{id}"),

  /// `GET`/`POST`. `index` accepts the optional `user_id`, `category_id`,
  /// `start_date` and `end_date` query filters.
  transactions("transactions"),

  /// `PUT`/`DELETE`.
  transactionById("transactions/{id}"),

  /// `GET`/`POST`.
  budgets("budgets"),

  /// `PUT`/`DELETE`.
  budgetById("budgets/{id}");

  final String endpoint;

  const GlobalApiEndpoint(this.endpoint);

  // Example 1: final endpoint = GlobalApiEndpoint.login.endpoint;
  // Example 2: final endpoint = GlobalApiEndpoint.showPages[['articles', 1]];
  String operator [](List<Object> params) {
    final regExp = RegExp(r"\{(.*?)\}");
    final urlParamsCount =
        endpoint.replaceAll(regExp, '[^]').split('[^]').length - 1;
    assert(
      urlParamsCount == params.length,
      'Endpoint params count not correct',
    );
    int foundedParams = -1;
    return endpoint.replaceAllMapped(regExp, (_) {
      foundedParams++;
      return params[foundedParams].toString();
    });
  }
}
