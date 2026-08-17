/// Конфигурация приложения.
/// Если API_BASE_URL не задан (через --dart-define) — демо-режим.
/// В демо-режиме приложение работает с тестовыми данными, без backend.
class AppConfig {
  /// Backend API base URL. Пустая строка = демо-режим.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Демо-режим — без backend, моковые данные.
  static bool get isDemoMode => apiBaseUrl.isEmpty;

  /// WebSocket URL.
  static String get wsBaseUrl =>
      apiBaseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');

  /// Request timeout.
  static const Duration requestTimeout = Duration(seconds: 15);
}
