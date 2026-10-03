import 'dart:async';
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
    final candidateUrls = ApiConstants.candidateBaseUrls;
    http.Response? lastResponse;

    // Probar las URLs candidatas (USB con adb reverse, Emulador o Wi-Fi)
    for (final base in candidateUrls) {
      try {
        final url = Uri.parse('$base/auth/login');
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': email.trim(),
                'password': password,
              }),
            )
            .timeout(const Duration(seconds: 3));

        // Si el servidor respondió (cualquier código HTTP), encontramos el backend activo
        ApiConstants.setActiveBaseUrl(base);
        lastResponse = response;
        break;
      } on TimeoutException {
        // Continuar al siguiente candidato
        continue;
      } catch (_) {
        // Continuar al siguiente candidato
        continue;
      }
    }

    if (lastResponse == null) {
      throw AuthException(
        'No se pudo conectar con el servidor backend.\nVerifica que esté corriendo en tu computador.',
      );
    }

    if (lastResponse.statusCode == 200 || lastResponse.statusCode == 201) {
      final data = jsonDecode(lastResponse.body) as Map<String, dynamic>;
      return AuthResponse.fromJson(data);
    } else {
      try {
        final errorData = jsonDecode(lastResponse.body);
        final message = errorData['message'];
        if (message is List) {
          throw AuthException(message.join(', '));
        } else if (message is String) {
          throw AuthException(message);
        }
      } catch (e) {
        if (e is AuthException) rethrow;
      }
      throw AuthException('Credenciales inválidas o error en el servidor (${lastResponse.statusCode})');
    }
  }
}
