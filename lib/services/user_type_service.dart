import 'package:firebase_database/firebase_database.dart';

// Enum para representar os tipos de usuário de forma segura
enum UserType { client, establishment, none, unknown }

class UserTypeService {
  /// Verifica no banco de dados se o UID pertence a um cliente ou a um estabelecimento.
  static Future<UserType> getUserType(String uid) async {
    try {
      final dbRef = FirebaseDatabase.instance.ref();

      // Checa primeiro se o UID existe no nó de estabelecimentos
      final establishmentSnapshot =
          await dbRef.child('estabelecimentos/$uid').get();
      if (establishmentSnapshot.exists) {
        return UserType.establishment;
      }

      // Se não for estabelecimento, checa se existe no nó de usuários (clientes)
      final userSnapshot = await dbRef.child('users/$uid').get();
      if (userSnapshot.exists) {
        return UserType.client;
      }

      // Se não existe em nenhum dos dois, é um usuário desconhecido (pode ser um erro)
      return UserType.none;
    } catch (e) {
      print("Erro ao verificar tipo de usuário: $e");
      return UserType.unknown;
    }
  }
}
