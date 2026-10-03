import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _currentUser != null;

  AuthProvider() {
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      final userDataStr = prefs.getString('auth_user');

      if (_token != null && userDataStr != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userDataStr));
        notifyListeners();
      }
    } catch (_) {
      // Ignorar error al cargar sesión inicial
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _token = response.accessToken;
      _currentUser = response.user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('auth_user', jsonEncode(_currentUser!.toJson()));

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
