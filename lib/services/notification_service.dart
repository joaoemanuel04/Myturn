import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print(
    "Notificação em Segundo Plano recebida: ${message.notification?.title}",
  );
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
        'Notificação em Primeiro Plano recebida: ${message.notification?.title}',
      );
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Agora a chamada corresponde à definição da função
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      saveTokenToDatabase(token); // Passando o novo token diretamente
    });
  }

  // MÉTODO CORRIGIDO
  // Agora ele aceita um token como argumento opcional.
  Future<void> saveTokenToDatabase([String? newToken]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // LÓGICA CORRIGIDA:
    // 1. Se um 'newToken' foi passado (pelo onTokenRefresh), usa ele.
    // 2. Se não, busca o token atual do dispositivo (usado após o login).
    final String? tokenToSave = newToken ?? await _firebaseMessaging.getToken();

    if (tokenToSave == null) {
      print("Não foi possível obter ou encontrar o token FCM para salvar.");
      return;
    }

    final tokenRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/fcmToken',
    );
    await tokenRef.set(tokenToSave);
    print("Token FCM salvo para o usuário: ${user.uid}");
  }
}
