import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Retorna la URL base según la plataforma de ejecución:
  /// - En Android Emulator, el host local es 10.0.2.2
  /// - En Web o Desktop (Windows) es localhost
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  static String get loginUrl => '$baseUrl/auth/login';
  static String get profileUrl => '$baseUrl/auth/profile';
  static String get machinesUrl => '$baseUrl/machines';
  static String get transportUrl => '$baseUrl/transport';
}
