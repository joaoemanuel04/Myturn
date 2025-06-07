// lib/models/estabelecimento_model.dart

import 'package:myturn/models/horario_model.dart';

class EstabelecimentoModel {
  final String uid;
  final String name;
  final String email;
  final String categoria;
  final String cnpj;
  final String celular;
  final String estado;
  final String cidade;
  final bool filaAberta;
  final int contagemFila;
  final bool emailVerified; // ALTERAÇÃO: Novo campo adicionado
  final Map<String, HorarioModel> horarios;

  EstabelecimentoModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.categoria,
    required this.cnpj,
    required this.celular,
    required this.estado,
    required this.cidade,
    this.filaAberta = false,
    this.contagemFila = 0,
    this.emailVerified = false, // ALTERAÇÃO: Novo campo adicionado
    required this.horarios,
  });

  factory EstabelecimentoModel.fromMap(Map<String, dynamic> map) {
    final Map<String, HorarioModel> horariosConvertidos = {};
    if (map['horarios'] is Map) {
      final horariosData = Map<String, dynamic>.from(map['horarios']);
      horariosData.forEach((dia, horarioMap) {
        horariosConvertidos[dia] = HorarioModel.fromMap(
          Map<String, dynamic>.from(horarioMap),
        );
      });
    }

    return EstabelecimentoModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'Nome não disponível',
      email: map['email'] ?? '',
      categoria: map['categoria'] ?? 'Sem categoria',
      cnpj: map['cnpj'] ?? '',
      celular: map['celular'] ?? '',
      estado: map['estado'] ?? '',
      cidade: map['cidade'] ?? '',
      filaAberta: map['filaAberta'] ?? false,
      emailVerified:
          map['emailVerified'] ?? false, // ALTERAÇÃO: Novo campo adicionado
      horarios: horariosConvertidos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'categoria': categoria,
      'cnpj': cnpj,
      'celular': celular,
      'estado': estado,
      'cidade': cidade,
      'filaAberta': filaAberta,
      'emailVerified': emailVerified, // ALTERAÇÃO: Novo campo adicionado
      'horarios': horarios.map(
        (dia, horario) => MapEntry(dia, horario.toMap()),
      ),
    };
  }

  EstabelecimentoModel copyWith({
    bool? filaAberta,
    int? contagemFila,
    bool? emailVerified,
  }) {
    return EstabelecimentoModel(
      uid: uid,
      name: name,
      email: email,
      categoria: categoria,
      cnpj: cnpj,
      celular: celular,
      estado: estado,
      cidade: cidade,
      horarios: horarios,
      filaAberta: filaAberta ?? this.filaAberta,
      contagemFila: contagemFila ?? this.contagemFila,
      emailVerified:
          emailVerified ??
          this.emailVerified, // ALTERAÇÃO: Novo campo adicionado
    );
  }
}
