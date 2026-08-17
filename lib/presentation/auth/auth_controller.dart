import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../data/api/auth_api.dart';
import '../../data/models/auth_models.dart';
import '../../domain/entities/auth_state.dart';

/// AuthController — управляет аутентификацией через Riverpod.
/// AsyncNotifier<AuthState?> — null когда не залогинен, AuthState когда залогинен.
class AuthController extends AsyncNotifier<AuthState?> {
  late final AuthApi _authApi;
  late final SecureStorage _storage;

  @override
  Future<AuthState?> build() async {
    // Демо-режим — без backend, сразу залогинен.
    if (AppConfig.isDemoMode) {
      return AuthState(
        userId: 'demo-user',
        shopId: 'demo-shop',
        role: 'owner',
        displayName: 'Демо',
      );
    }

    _authApi = ref.watch(authApiProvider);
    _storage = ref.watch(secureStorageProvider);

    // Проверяем есть ли токен в storage (оборачиваем в try/catch для web).
    try {
      final access = await _storage.getAccessToken();
      if (access != null && access.isNotEmpty) {
        final userId = await _storage.getUserId() ?? '';
        if (userId.isNotEmpty) {
          return AuthState(
            userId: userId,
            shopId: await _storage.getShopId() ?? '',
            role: await _storage.getRole() ?? 'owner',
            displayName: await _storage.getDisplayName() ?? '',
          );
        }
      }
    } catch (_) {
      // flutter_secure_storage падает на web без HTTPS — продолжаем к auto-login.
    }

    // Нет токена — авто-вход под demo пользователем.
    // Пользователь не видит login/register — сразу в приложение.
    try {
      print('AUTH: trying login...');
      final resp = await _authApi.login(LoginRequest(
        email: 'demo@autocalendar.local',
        password: 'demo12345',
      ));
      print('AUTH: login OK, saving...');
      try {
        await _storage.saveAuth(
          accessToken: resp.access,
          refreshToken: resp.refresh,
          userId: resp.userId,
          shopId: resp.shopId,
          role: resp.role,
          displayName: resp.displayName ?? 'Демо',
        );
      } catch (e) {
        print('AUTH: saveAuth error: $e');
      }
      print('AUTH: returning AuthState');
      return AuthState(
        userId: resp.userId,
        shopId: resp.shopId,
        role: resp.role,
        displayName: resp.displayName ?? 'Демо',
      );
    } catch (e) {
      print('AUTH: login failed: $e');
      // Login не удался — регистрируем demo.
      try {
        final resp = await _authApi.register(RegisterRequest(
          shopName: 'Демо-сервис',
          email: 'demo@autocalendar.local',
          password: 'demo12345',
          displayName: 'Демо',
        ));
        try {
          await _storage.saveAuth(
            accessToken: resp.access,
            refreshToken: resp.refresh,
            userId: resp.userId,
            shopId: resp.shopId,
            role: resp.role,
            displayName: 'Демо',
          );
        } catch (_) {}
        return AuthState(
          userId: resp.userId,
          shopId: resp.shopId,
          role: resp.role,
          displayName: 'Демо',
        );
      } catch (e) {
        print('AUTH: register also failed: $e');
        // Совсем не получилось — вернём null, API запросы будут падать.
        return null;
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final resp = await _authApi.login(LoginRequest(email: email, password: password));
      // try/catch: на web без HTTPS (http://IP:port) flutter_secure_storage
      // может падать (SubtleCrypto требует secure context). Токен всё равно
      // остаётся в памяти через AuthState — приложение работает до reload.
      try {
        await _storage.saveAuth(
          accessToken: resp.access,
          refreshToken: resp.refresh,
          userId: resp.userId,
          shopId: resp.shopId,
          role: resp.role,
          displayName: resp.displayName ?? '',
        );
      } catch (_) {
        // ignore — продолжаем без персистентного storage.
      }
      return AuthState(
        userId: resp.userId,
        shopId: resp.shopId,
        role: resp.role,
        displayName: resp.displayName ?? '',
      );
    });
  }

  Future<void> register(RegisterRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final resp = await _authApi.register(req);
      try {
        await _storage.saveAuth(
          accessToken: resp.access,
          refreshToken: resp.refresh,
          userId: resp.userId,
          shopId: resp.shopId,
          role: resp.role,
          displayName: req.displayName,
        );
      } catch (_) {
        // ignore — на web без HTTPS storage может падать.
      }
      return AuthState(
        userId: resp.userId,
        shopId: resp.shopId,
        role: resp.role,
        displayName: req.displayName,
      );
    });
  }

  Future<void> logout() async {
    try {
      await _storage.clear();
    } catch (_) {
      // ignore на web без HTTPS.
    }
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState?>(AuthController.new);
