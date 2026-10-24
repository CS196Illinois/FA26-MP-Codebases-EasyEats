/// Base URL of the EasyEats backend API.
///
/// Defaults to the local backend. To point the app somewhere else, for example
/// the Android emulator address, run:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);
