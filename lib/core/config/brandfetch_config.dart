/// Brandfetch API client ID. Must be injected at build time via `--dart-define`.
/// Empty when not provided — brand-fetch features will be disabled.
///
/// Example: `flutter run --dart-define=BRANDFETCH_CLIENT_ID=your_id`
const brandfetchClientId = String.fromEnvironment(
  'BRANDFETCH_CLIENT_ID',
);
