/// DTO для /api/auth/register и /api/auth/login.
class RegisterRequest {
  final String shopName;
  final String email;
  final String phone;
  final String password;
  final String displayName;
  final String timezone;

  RegisterRequest({
    required this.shopName,
    required this.email,
    this.phone = '',
    required this.password,
    required this.displayName,
    this.timezone = 'Europe/Moscow',
  });

  Map<String, dynamic> toJson() => {
        'shop_name': shopName,
        'email': email,
        'phone': phone,
        'password': password,
        'display_name': displayName,
        'timezone': timezone,
      };
}

class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class AuthResponse {
  final String shopId;
  final String userId;
  final String role;
  final String? displayName;
  final String access;
  final String refresh;

  AuthResponse({
    required this.shopId,
    required this.userId,
    required this.role,
    this.displayName,
    required this.access,
    required this.refresh,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      shopId: json['shop_id'] ?? json['ShopID'] ?? '',
      userId: json['user_id'] ?? json['UserID'] ?? '',
      role: json['role'] ?? '',
      displayName: json['display_name'],
      access: json['access'] ?? '',
      refresh: json['refresh'] ?? '',
    );
  }
}

class RefreshRequest {
  final String refresh;
  RefreshRequest(this.refresh);
  Map<String, dynamic> toJson() => {'refresh': refresh};
}

class RefreshResponse {
  final String access;
  final String refresh;
  RefreshResponse({required this.access, required this.refresh});
  factory RefreshResponse.fromJson(Map<String, dynamic> json) => RefreshResponse(
        access: json['access'] ?? '',
        refresh: json['refresh'] ?? '',
      );
}
