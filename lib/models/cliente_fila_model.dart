class ClienteFilaModel {
  final String uid;
  final String nome;
  final DateTime horaEntrada;

  ClienteFilaModel({
    required this.uid,
    required this.nome,
    required this.horaEntrada,
  });

  // Note que aqui o factory recebe o ID (key) e o Map (value) separadamente
  factory ClienteFilaModel.fromMap(String uid, Map<String, dynamic> map) {
    return ClienteFilaModel(
      uid: uid,
      nome: map['nome'] ?? 'Cliente anônimo',
      // Tratamento para garantir que a data seja válida
      horaEntrada:
          DateTime.tryParse(map['horaEntrada'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'nome': nome, 'horaEntrada': horaEntrada.toIso8601String()};
  }
}
