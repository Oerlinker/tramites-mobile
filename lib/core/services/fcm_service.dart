import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:tramites_mobile/core/services/api_service.dart';

class FcmService {
  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> initialize(
    ApiService apiService,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    _navigatorKey = navigatorKey;
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null) {
      await _enviarTokenAlBackend(token, apiService);
    }

    messaging.onTokenRefresh.listen((newToken) {
      _enviarTokenAlBackend(newToken, apiService);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // ignore: avoid_print
      print('Notificación foreground: ${message.notification?.title}');
      if (message.notification != null) {
        _mostrarNotificacionForeground(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
        );
      }
    });
  }

  static void _mostrarNotificacionForeground(String titulo, String cuerpo) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(cuerpo),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> _enviarTokenAlBackend(
    String token,
    ApiService apiService,
  ) async {
    try {
      // ignore: avoid_print
      print('FCM TOKEN: $token');
      // ignore: avoid_print
      print('Enviando token al backend...');
      final response = await apiService.dio.post<void>(
        '/usuarios/me/fcm-token',
        data: {'token': token},
      );
      // ignore: avoid_print
      print('FCM token guardado. Status: ${response.statusCode}');
    } catch (e) {
      // ignore: avoid_print
      print('ERROR guardando FCM token: $e');
    }
  }
}
