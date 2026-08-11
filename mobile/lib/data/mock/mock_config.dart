/// The single switch between fake and real data for the whole app.
///
/// ---------------------------------------------------------------------------
/// There is deliberately **one** flag, not one per repository. `DashboardRepo`
/// and `TransactionsRepo` both read it, so the app can never end up in a
/// half-mocked state where one screen shows seeded rows and another shows live
/// ones.
///
/// Why it is still `true`:
///   * `GlobalApiEndpoint.base` is the placeholder `https://domain/api/v1`, and
///     the Laravel backend on the unmerged branch `origin/souad-backend` serves
///     `/api/transactions` — the `/v1` prefix does not even exist there.
///   * `routes/api.php` applies no middleware and `bootstrap/app.php`'s
///     `withMiddleware` closure is empty, so nothing scopes rows to the signed-in
///     user and there are no login/register routes.
///   * Of the three transaction write operations, only `destroy()` is
///     implemented. `store()` never sets the NOT NULL `user_id` column, and
///     `update()` is an empty stub — see `TransactionsRepo` for the details.
///
/// To go live: implement the `_remote*` methods in the repositories, flip this
/// to `false`, and delete `lib/data/mock/`.
/// ---------------------------------------------------------------------------
const bool kUseMockData = true;
