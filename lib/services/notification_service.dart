import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // Importe para usar o debugPrint

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    "Notificação em Segundo Plano recebida: ${message.notification?.title}",
  );
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Verifica o status da permissão e, se necessário, solicita ao usuário.
  Future<void> requestNotificationPermission() async {
    NotificationSettings settings =
        await _firebaseMessaging.getNotificationSettings();

    // ADICIONAMOS LOGS PARA DIAGNÓSTICO
    debugPrint("--- diagnóstico de permissão de notificação ---");
    debugPrint(
      "Status da permissão ANTES de pedir: ${settings.authorizationStatus}",
    );

    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      debugPrint("Permissão ainda não foi determinada. Solicitando...");
      settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

    debugPrint(
      "Status da permissão DEPOIS de pedir: ${settings.authorizationStatus}",
    );
    debugPrint("--- fim do diagnóstico ---");
  }

  /// Inicializa os listeners para mensagens e token.
  Future<void> initNotifications() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'Notificação em Primeiro Plano recebida: ${message.notification?.title}',
      );
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _firebaseMessaging.onTokenRefresh.listen((String token) {
      saveTokenToDatabase(token);
    });
  }

  /// Salva o token FCM no banco de dados.
  Future<void> saveTokenToDatabase([String? newToken]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String? tokenToSave = newToken ?? await _firebaseMessaging.getToken();

    if (tokenToSave == null) {
      debugPrint("Não foi possível obter o token FCM para salvar.");
      return;
    }

    final tokenRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/fcmToken',
    );
    await tokenRef.set(tokenToSave);
    debugPrint("Token FCM salvo para o usuário: ${user.uid}");
  }
}
