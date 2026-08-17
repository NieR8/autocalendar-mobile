import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';

/// Dio-клиент с AuthInterceptor + web CORS fix (text/plain content-type).

String _webSafeContentType() =>
    kIsWeb ? 'text/plain;charset=utf-8' : 'application/json';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.requestTimeout,
    receiveTimeout: AppConfig.requestTimeout,
    contentType: _webSafeContentType(),
    headers: kIsWeb ? {} : {
      // bypass-tunnel-reminder нужен для localtunnel,
      // Ngrok-Skip-Browser-Warning: true — для ngrok free captha.
      // Оба заголовка — custom, ломают CORS preflight на web. На native OK.
      'bypass-tunnel-reminder': 'true',
      'Ngrok-Skip-Browser-Warning': 'true',
    },
  ));
  dio.interceptors.add(AuthInterceptor(storage: storage, ref: ref));
  if (kIsWeb) {
    dio.interceptors.add(_WebJsonEncoder());
  }
  return dio;
});

/// На web Dio сериализует data как JSON в string, content-type text/plain
/// не вызывает preflight. Interceptor кодирует Map/List в JSON-string.
class _WebJsonEncoder extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.data is Map || options.data is List) {
      options.data = jsonEncode(options.data);
    }
    handler.next(options);
  }
}

/// AuthInterceptor — синхронный (без async в onRequest).
/// Читает токен через storage.getAccessTokenSync() — из memory кэша,
/// который заполняется saveAuth() в auth_controller.
class AuthInterceptor extends Interceptor {
  final SecureStorage storage;
  final Ref ref;

  AuthInterceptor({required this.storage, required this.ref});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    if (path.contains('/api/auth/')) {
      return handler.next(options);
    }
    final token = storage.getAccessTokenSync();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }
    final refreshed = await _tryRefresh(err.requestOptions);
    if (refreshed) {
      try {
        final retryDio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          contentType: _webSafeContentType(),
        ));
        final response = await retryDio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (_) {
        return handler.next(err);
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh(RequestOptions original) async {
    final refresh = storage.getRefreshTokenSync();
    if (refresh == null) return false;
    try {
      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        contentType: _webSafeContentType(),
      ));
      final resp = await refreshDio.post(
        '/api/auth/refresh',
        data: kIsWeb ? jsonEncode({'refresh': refresh}) : {'refresh': refresh},
      );
      if (resp.statusCode == 200) {
        final data = resp.data as Map<String, dynamic>;
        try {
          await storage.saveAuth(
            accessToken: data['access'] as String,
            refreshToken: data['refresh'] as String,
            userId: await storage.getUserId() ?? '',
            shopId: await storage.getShopId() ?? '',
            role: await storage.getRole() ?? '',
          );
        } catch (_) {}
        original.headers['Authorization'] = 'Bearer ${data['access']}';
        return true;
      }
    } catch (_) {
      try {
        await storage.clear();
      } catch (_) {}
    }
    return false;
  }
}
