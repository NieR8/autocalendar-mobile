/// Состояние аутентификации.
class AuthState {
  final String userId;
  final String shopId;
  final String role;
  final String displayName;

  AuthState({
    required this.userId,
    required this.shopId,
    required this.role,
    this.displayName = '',
  });

  bool get isOwner => role == 'owner';
  bool get isWorker => role == 'worker';
}
