import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.fromJson(data);
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final message = errorData['message'];
          if (message is List) {
            throw AuthException(message.join(', '));
          } else if (message is String) {
            throw AuthException(message);
          }
        } catch (e) {
          if (e is AuthException) rethrow;
        }
        throw AuthException('Credenciales inválidas o error en el servidor (${response.statusCode})');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('No se pudo conectar con el servidor. Verifica que el backend esté activo.');
    }
  }
}
