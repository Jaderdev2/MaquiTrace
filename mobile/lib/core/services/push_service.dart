import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class PushService {
  PushService._();
  static final instance = PushService._();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _available = false;
  String? _session;
  StreamSubscription<String>? _tokenSubscription;
  Timer? _retryTimer;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Firebase.initializeApp();
      _available = true;
      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        if (_session == null) return;
        messengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
              'Tienes una nueva notificación. Consulta la bandeja.',
            ),
          ),
        );
      });
    } catch (error) {
      debugPrint('No se pudo iniciar Firebase: $error');
    }
  }

  Future<void> register(String session) async {
    if (!_available) return;
    _session = session;
    await _tokenSubscription?.cancel();
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _syncToken(session),
    );
    try {
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission();
      if (_session != session ||
          permission.authorizationStatus != AuthorizationStatus.authorized) {
        _retryTimer?.cancel();
        return;
      }
      // FCM HTTP v1 currently addresses devices using registration tokens.
      // ignore: deprecated_member_use
      _tokenSubscription = messaging.onTokenRefresh.listen(
        (token) => _saveToken(session, token),
      );
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null && _session == session) {
        await _saveToken(session, token);
      }
    } catch (error) {
      debugPrint('No se pudo registrar el dispositivo: $error');
    }
  }

  Future<void> _syncToken(String session) async {
    if (_session != session) return;
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(session, token);
    } catch (_) {}
  }

  Future<void> _saveToken(String session, String token) async {
    if (_session != session) return;
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/notifications/devices'),
            headers: {
              'Authorization': 'Bearer $session',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 400) {
        debugPrint(
          'No se pudo registrar el dispositivo: HTTP ${response.statusCode}',
        );
      }
    } catch (error) {
      debugPrint('No se pudo registrar el dispositivo: $error');
    }
  }

  Future<void> unregister(String? session) async {
    _session = null;
    _retryTimer?.cancel();
    await _tokenSubscription?.cancel();
    if (!_available || session == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) {
        await http
            .delete(
              Uri.parse('${ApiConstants.baseUrl}/notifications/devices'),
              headers: {
                'Authorization': 'Bearer $session',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'token': token}),
            )
            .timeout(const Duration(seconds: 5));
      }
    } catch (error) {
      debugPrint('No se pudo desvincular el dispositivo: $error');
    }
    try {
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  void dispose() {
    _retryTimer?.cancel();
    _messageSubscription?.cancel();
    _tokenSubscription?.cancel();
  }
}
