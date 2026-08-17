import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/auth_models.dart';

/// API-клиент для /api/auth/*.
class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<AuthResponse> register(RegisterRequest req) async {
    final resp = await _dio.post('/api/auth/register', data: req.toJson());
    return AuthResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<AuthResponse> login(LoginRequest req) async {
    final resp = await _dio.post('/api/auth/login', data: req.toJson());
    return AuthResponse.fromJson(resp.data as Map<String, dynamic>);
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));
