import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String port = '3000';
  static const String apiPath = '/api/v1';

  /// IP local de tu computador en la red Wi-Fi (para cuando no uses cable USB)
  static const String localWifiIp = '192.168.1.17';

  /// Base URL activa detectada dinámicamente
  static String? _activeBaseUrl;

  static String get baseUrl {
    if (_activeBaseUrl != null) {
      return _activeBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:$port$apiPath';
    }
    if (Platform.isAndroid) {
      // Por defecto intenta localhost (funciona con USB + adb reverse)
      return 'http://localhost:$port$apiPath';
    }
    return 'http://localhost:$port$apiPath';
  }

  static void setActiveBaseUrl(String url) {
    _activeBaseUrl = url;
  }

  /// Lista de URLs candidatas para detectar automáticamente el backend:
  /// 1. localhost:3000 (funciona en celular físico con cable USB gracias a adb reverse)
  /// 2. 10.0.2.2:3000 (funciona en el Emulador de Android Studio)
  /// 3. 192.168.1.17:3000 (funciona en celular físico conectado a la misma red Wi-Fi)
  static List<String> get candidateBaseUrls {
    if (kIsWeb) return ['http://localhost:$port$apiPath'];
    if (Platform.isAndroid) {
      return [
        'http://localhost:$port$apiPath',
        'http://10.0.2.2:$port$apiPath',
        'http://$localWifiIp:$port$apiPath',
      ];
    }
    return ['http://localhost:$port$apiPath'];
  }

  static String get loginUrl => '$baseUrl/auth/login';
  static String get profileUrl => '$baseUrl/auth/profile';
  static String get machinesUrl => '$baseUrl/machines';
  static String get transportUrl => '$baseUrl/transport';
}
