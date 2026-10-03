class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'operario',
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
    };
  }

  bool get isOperario => role.toLowerCase() == 'operario';
  bool get isTransportador => role.toLowerCase() == 'transportador';
  bool get isAdmin => role.toLowerCase() == 'administrador' || role.toLowerCase() == 'admin';
}

class AuthResponse {
  final String accessToken;
  final UserModel user;

  AuthResponse({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}
