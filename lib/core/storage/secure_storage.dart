import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Безопасное хранилище для JWT-токенов с memory fallback + sync кэш.
///
/// На web без HTTPS SubtleCrypto недоступен, write падает. Переключаемся
/// на in-memory map. Также храним _sync cache чтобы Dio interceptor мог
/// читать токен синхронно (без async в onRequest).
class SecureStorage {
  static const _keyAccess = 'jwt_access';
  static const _keyRefresh = 'jwt_refresh';
  static const _keyUserId = 'user_id';
  static const _keyShopId = 'shop_id';
  static const _keyRole = 'user_role';
  static const _keyDisplayName = 'display_name';

  final FlutterSecureStorage _storage;
  final Map<String, String> _memory = {};
  bool _useMemory = false;

  // Sync кэш для Dio interceptor (без async в onRequest)
  String? _syncAccess;
  String? _syncRefresh;

  SecureStorage() : _storage = const FlutterSecureStorage();

  Future<void> saveAuth({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String shopId,
    required String role,
    String displayName = '',
  }) async {
    // Sync кэш — ВСЕГДА обновляем, даже если storage падает
    _syncAccess = accessToken;
    _syncRefresh = refreshToken;

    final entries = {
      _keyAccess: accessToken,
      _keyRefresh: refreshToken,
      _keyUserId: userId,
      _keyShopId: shopId,
      _keyRole: role,
      _keyDisplayName: displayName,
    };
    _memory.addAll(entries);

    if (_useMemory) return;
    try {
      await Future.wait(entries.entries.map(
        (e) => _storage.write(key: e.key, value: e.value),
      ));
    } catch (_) {
      _useMemory = true;
    }
  }

  /// Sync — для Dio interceptor (без async в onRequest)
  String? getAccessTokenSync() => _syncAccess ?? _memory[_keyAccess];
  String? getRefreshTokenSync() => _syncRefresh ?? _memory[_keyRefresh];

  Future<String?> getAccessToken() async => getAccessTokenSync();
  Future<String?> getRefreshToken() async => getRefreshTokenSync();
  Future<String?> getUserId() => _read(_keyUserId);
  Future<String?> getShopId() => _read(_keyShopId);
  Future<String?> getRole() => _read(_keyRole);
  Future<String?> getDisplayName() => _read(_keyDisplayName);

  Future<String?> _read(String key) async {
    if (_syncAccess != null) {
      // Уже залогинены через sync saveAuth — берём из памяти
      return _memory[key];
    }
    if (_useMemory) return _memory[key];
    try {
      final v = await _storage.read(key: key);
      if (v != null) {
        _memory[key] = v;
        // Заполняем sync кэш из localStorage
        if (key == _keyAccess) _syncAccess = v;
        if (key == _keyRefresh) _syncRefresh = v;
      }
      return v;
    } catch (_) {
      _useMemory = true;
      return _memory[key];
    }
  }

  Future<void> clear() async {
    _memory.clear();
    _syncAccess = null;
    _syncRefresh = null;
    if (_useMemory) return;
    try {
      await _storage.deleteAll();
    } catch (_) {
      _useMemory = true;
    }
  }
}

/// Riverpod provider для SecureStorage (singleton).
final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());
