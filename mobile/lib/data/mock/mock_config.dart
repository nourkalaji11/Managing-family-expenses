/// The single switch between fake and real data for the whole app.
///
/// ---------------------------------------------------------------------------
/// There is deliberately **one** flag, not one per repository. Every repository
/// reads it, so the app can never end up half-mocked — showing seeded rows on
/// one screen and live ones on the next, with totals that disagree.
///
/// Set at build time, so switching does not mean editing a tracked file:
///
///     flutter run --dart-define=USE_MOCK=false \
///                 --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
///
/// The default is `true`: the app runs entirely offline out of the box, which
/// is what a designer reviewing a screen or a developer with no Laravel server
/// running actually needs. Nothing in the mock path touches the network, so a
/// mock build with no `API_BASE_URL` is a complete, working app rather than a
/// wall of connection errors.
///
/// Going live is one flag and one URL — see `GlobalApiEndpoint.base`.
/// ---------------------------------------------------------------------------
const bool kUseMockData = bool.fromEnvironment('USE_MOCK', defaultValue: true);
