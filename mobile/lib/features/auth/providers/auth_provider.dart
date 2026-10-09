import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/biometric_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _canUseBiometric = false;
  bool _isBiometricEnabled = false;
  bool _hasSavedCredentials = false;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get canUseBiometric => _canUseBiometric;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get hasSavedCredentials => _hasSavedCredentials;
  BiometricService get biometricService => _biometricService;

  AuthProvider() {
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      ApiConstants.authToken = _token;
      final userDataStr = prefs.getString('auth_user');

      if (_token != null && userDataStr != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userDataStr));
      }

      await checkBiometricStatus();
    } catch (_) {
      // Ignorar error al cargar sesión inicial
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> checkBiometricStatus() async {
    try {
      _canUseBiometric = await _biometricService.canAuthenticate();
      _isBiometricEnabled = await _biometricService.isBiometricEnabled();
      final creds = await _biometricService.getCredentials();
      _hasSavedCredentials = creds != null;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> toggleBiometric(bool enable, {String? email, String? password}) async {
    if (enable) {
      final success = await _biometricService.authenticate(
        reason: 'Verifica tu identidad para activar el ingreso con huella',
      );
      if (!success) return false;

      if (email != null && password != null) {
        await _biometricService.saveCredentials(email, password);
      }
      await _biometricService.setBiometricEnabled(true);
      _isBiometricEnabled = true;
      final creds = await _biometricService.getCredentials();
      _hasSavedCredentials = creds != null;
      notifyListeners();
      return true;
    } else {
      await _biometricService.setBiometricEnabled(false);
      _isBiometricEnabled = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> loginWithBiometrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credentials = await _biometricService.getCredentials();
      if (credentials == null) {
        _errorMessage = 'No hay credenciales registradas para ingreso con huella.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final authenticated = await _biometricService.authenticate(
        reason: 'Toca el sensor de huella para ingresar a MaquiTrace',
      );
      if (!authenticated) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      return await login(
        credentials.email,
        credentials.password,
        rememberMe: true,
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _token = response.accessToken;
      _currentUser = response.user;
      ApiConstants.authToken = _token;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      if (rememberMe) {
        await prefs.setString('auth_user', jsonEncode(_currentUser!.toJson()));
      }

      // Guardar credenciales seguras si biometría está activa o recordar sesión
      if (_isBiometricEnabled || rememberMe) {
        await _biometricService.saveCredentials(email, password);
        _hasSavedCredentials = true;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _errorMessage = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
