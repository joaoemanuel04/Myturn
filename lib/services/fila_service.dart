// novo arquivo: lib/services/fila_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:myturn/models/cliente_fila_model.dart';

class FilaService {
  // Tornamos o método estático para que não precisemos instanciar a classe para usá-lo
  static Future<String> entrarNaFila(String estabelecimentoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return "Usuário não está logado.";
    }

    try {
      final dbRef = FirebaseDatabase.instance.ref();

      // Busca o nome do cliente no perfil dele
      final clienteSnapshot = await dbRef.child('users/${user.uid}').get();
      if (!clienteSnapshot.exists) {
        return "Seu perfil não foi encontrado. Não é possível entrar na fila.";
      }
      final dadosCliente = Map<String, dynamic>.from(
        clienteSnapshot.value as Map,
      );
      final nomeCliente = dadosCliente['name'] ?? 'Cliente sem nome';

      // Referências para a fila e para a reserva do usuário
      final filaRef = dbRef.child(
        'filas/$estabelecimentoId/clientes/${user.uid}',
      );
      final reservaUsuarioRef = dbRef.child(
        'minhasReservasPorUsuario/${user.uid}/$estabelecimentoId',
      );

      // Cria o objeto para ser salvo na fila
      final clienteParaFila = ClienteFilaModel(
        uid: user.uid,
        nome: nomeCliente,
        horaEntrada: DateTime.now(),
      );

      // Executa as duas operações em paralelo
      await Future.wait([
        filaRef.set(clienteParaFila.toMap()),
        reservaUsuarioRef.set(true),
      ]);

      return "success";
    } catch (e) {
      print("Erro ao entrar na fila via serviço: $e");
      return "Ocorreu um erro ao tentar entrar na fila.";
    }
  }
}
