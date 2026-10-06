import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String port = '3000';
  static const String apiPath = '/api/v1';

  /// URL de producción en la nube (Render con Neon PostgreSQL 24/7)
  static const String cloudBaseUrl = 'https://maquitrace-backend.onrender.com/api/v1';

  /// IP local principal de tu computador en la red Wi-Fi
  static const String localWifiIp = '192.168.1.102';

  /// Lista de IPs locales conocidas donde ejecutas el backend (Trabajo, Casa, etc.)
  static const List<String> knownWifiIps = [
    '192.168.1.102', // Wi-Fi actual (hoy)
    '192.168.1.100', // Wi-Fi Trabajo (ayer)
    '192.168.1.17',  // Wi-Fi Casa
  ];

  /// Base URL activa detectada dinámicamente
  static String? _activeBaseUrl;

  /// Token JWT activo en memoria
  static String? authToken;

  static String get baseUrl {
    if (_activeBaseUrl != null) {
      return _activeBaseUrl!;
    }
    // Por defecto usa la nube de Render (funciona desde cualquier lugar con 4G o Wi-Fi)
    return cloudBaseUrl;
  }

  static void setActiveBaseUrl(String url) {
    _activeBaseUrl = url;
  }

  /// Lista de URLs candidatas para detectar automáticamente el backend:
  /// 1. localhost:3000 (funciona en celular físico con cable USB gracias a adb reverse)
  /// 2. 192.168.1.100:3000 (funciona en Wi-Fi del Trabajo)
  /// 3. 192.168.1.17:3000 (funciona en Wi-Fi de la Casa)
  /// 4. 10.0.2.2:3000 (funciona en el Emulador de Android Studio)
  static List<String> get candidateBaseUrls {
    final list = <String>[];
    if (_activeBaseUrl != null && _activeBaseUrl!.isNotEmpty) {
      list.add(_activeBaseUrl!);
    }
    // Prioridad 1: Backend en la nube (Render)
    if (!list.contains(cloudBaseUrl)) {
      list.add(cloudBaseUrl);
    }
    if (kIsWeb) {
      if (!list.contains('http://localhost:$port$apiPath')) {
        list.add('http://localhost:$port$apiPath');
      }
      return list;
    }
    if (Platform.isAndroid) {
      final candidates = [
        'http://localhost:$port$apiPath',
        for (final ip in knownWifiIps) 'http://$ip:$port$apiPath',
        'http://10.0.2.2:$port$apiPath',
      ];
      for (final u in candidates) {
        if (!list.contains(u)) list.add(u);
      }
      return list;
    }
    if (!list.contains('http://localhost:$port$apiPath')) {
      list.add('http://localhost:$port$apiPath');
    }
    return list;
  }

  static String get loginUrl => '$baseUrl/auth/login';
  static String get profileUrl => '$baseUrl/auth/profile';
  static String get machinesUrl => '$baseUrl/machines';
  static String get transportUrl => '$baseUrl/transport';
}
