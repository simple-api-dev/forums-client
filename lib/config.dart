/// The demo key baked in at build time:
///
///     flutter build web --dart-define=SIMPLEAPI_KEY=<your key>
///
/// It is empty when not provided. Never write a key in the source: anything
/// passed this way ends up in the compiled JavaScript, so use a free demo key.
const configuredKey = String.fromEnvironment('SIMPLEAPI_KEY');

/// The SimpleAPI home page, where the back arrow in the app bar goes.
const homeUrl = 'https://simpleapi.dev';
