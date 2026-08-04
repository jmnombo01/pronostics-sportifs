import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class FcmService {
  final ApiService _apiService;

  FcmService(this._apiService);

  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) {
          debugPrint('Jeton FCM : $token');
          await _apiService.updateFcmToken(token);
        }

        await messaging.subscribeToTopic('topic_all');
        await messaging.subscribeToTopic('topic_vip');
        await messaging.subscribeToTopic('topic_montante');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Notification reçue au premier plan: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('FCM non disponible en mode simulation ou hors ligne: $e');
    }
  }
}
