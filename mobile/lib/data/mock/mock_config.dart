/// The single switch between fake and real data for the whole app.
///
/// ---------------------------------------------------------------------------
/// There is deliberately **one** flag, not one per repository. `DashboardRepo`,
/// `TransactionsRepo` and `BudgetsRepo` all read it, so the app can never end up
/// in a half-mocked state where one screen shows seeded rows and another shows
/// live ones.
///
/// It is now `false`: every repository calls the Laravel API. The mock path is
/// deliberately **kept compiling** rather than deleted — with the flag off it is
/// dead code that costs nothing, and it buys a one-line rollback if the backend
/// is unreachable during a demo.
///
/// Running against a local server also needs the base URL, which is supplied at
/// build time so a developer's address never has to be committed:
///
///     flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
///
/// See `GlobalApiEndpoint.base`. With no `--dart-define` the app points at the
/// `https://domain/api` placeholder and fails loudly, which is the intended
/// behaviour — it must not silently talk to whoever last edited that file.
/// ---------------------------------------------------------------------------
const bool kUseMockData = false;
