import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/entities/auth_state.dart';
import '../presentation/auth/auth_controller.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/register_screen.dart';
import '../presentation/home/home_screen.dart';

/// Роутер на go_router: /login, /register, /.
/// AuthController определяет, какой маршрут показывать.
///
/// Паттерн правильной интеграции Riverpod + GoRouter:
/// 1. redirect читает СВЕЖЕЕ значение через `ref.read` (не замыкание).
/// 2. `ref.listen` на authControllerProvider вызывает `goRouter.refresh()`
///    при изменении state → redirect перевыполняется → редирект.
final routerProvider = Provider<GoRouter>((ref) {
  final goRouter = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Без обязательного auth — всегда пускаем.
      // Demo-вход происходит автоматически в AuthController.build().
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );
  // При изменении auth state (login/register/logout) — refresh → redirect.
  ref.listen(authControllerProvider, (_, __) {
    goRouter.refresh();
  });
  return goRouter;
});
