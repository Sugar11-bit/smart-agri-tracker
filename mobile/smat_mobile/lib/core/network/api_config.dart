/// Local Android development uses adb reverse tcp:8080 tcp:8080.
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );
  static const requestTimeout = Duration(seconds: 12);

  static const String login = '/api/v1/auth/login';

  static const String me = '/api/v1/auth/me';

  static const String myPlots = '/api/v1/me/plots';

  static const String farmingLogs = '/api/v1/me/farming-logs';
}
