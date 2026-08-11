import 'package:flutter/foundation.dart';
import 'api_service.dart';

class FcmService {
  final ApiService _apiService;

  FcmService(this._apiService);

  Future<void> initialize() async {
    try {
      debugPrint('🐸 [FCM Service] Initialisé en mode natif / simulation de notifications push.');
      // Permet au backend d'envoyer les alertes Frogazz en mode test
      await _apiService.updateFcmToken("fcm_token_frogazz_mobile_simulation");
    } catch (e) {
      debugPrint('Erreur init FCM: $e');
    }
  }
}
