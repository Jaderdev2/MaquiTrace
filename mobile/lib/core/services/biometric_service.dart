import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _prefBiometricEnabled = 'biometric_auth_enabled';
  static const String _keySecureEmail = 'secure_login_email';
  static const String _keySecurePassword = 'secure_login_password';

  /// Verifica si el hardware del dispositivo soporta biometría y si está registrada
  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Error verificando soporte: $e');
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Error verificando soporte: $e');
      return false;
    }
  }

  /// Obtiene qué tipos de biometría tiene el teléfono (huella, rostro, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Verifica si el usuario activó la opción de huella en MaquiTrace
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefBiometricEnabled) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Activa o desactiva la opción biométrica
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefBiometricEnabled, enabled);
    if (!enabled) {
      await clearCredentials();
    }
  }

  /// Guarda de forma segura las credenciales para el inicio biométrico
  Future<void> saveCredentials(String email, String password) async {
    try {
      await _secureStorage.write(key: _keySecureEmail, value: email.trim());
      await _secureStorage.write(key: _keySecurePassword, value: password);
    } catch (e) {
      debugPrint('[BiometricService] Error guardando credenciales seguras: $e');
    }
  }

  /// Obtiene las credenciales seguras almacenadas
  Future<({String email, String password})?> getCredentials() async {
    try {
      final email = await _secureStorage.read(key: _keySecureEmail);
      final password = await _secureStorage.read(key: _keySecurePassword);
      if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
        return (email: email, password: password);
      }
    } catch (e) {
      debugPrint('[BiometricService] Error leyendo credenciales seguras: $e');
    }
    return null;
  }

  /// Elimina las credenciales seguras almacenadas
  Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: _keySecureEmail);
      await _secureStorage.delete(key: _keySecurePassword);
    } catch (_) {}
  }

  /// Ejecuta la autenticación biométrica en el hardware
  Future<bool> authenticate({
    String reason = 'Confirma tu identidad para acceder a MaquiTrace',
  }) async {
    try {
      final can = await canAuthenticate();
      if (!can) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
        biometricOnly: false, // Permite PIN/patrón de contingencia si falla el sensor
      );
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Error de autenticación: $e');
      return false;
    } catch (e) {
      debugPrint('[BiometricService] Error de autenticación: $e');
      return false;
    }
  }
}
