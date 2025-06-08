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
  final bool emailVerified;
  // ALTERAÇÃO: Adicionados campos para as coordenadas
  final double? latitude;
  final double? longitude;
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
    this.emailVerified = false,
    // ALTERAÇÃO: Adicionados ao construtor como opcionais
    this.latitude,
    this.longitude,
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
      // ALTERAÇÃO: Lendo as coordenadas do mapa do Firebase.
      // A conversão (cast) para num e depois para double garante segurança.
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      filaAberta: map['filaAberta'] ?? false,
      emailVerified: map['emailVerified'] ?? false,
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
      'emailVerified': emailVerified,
      // ALTERAÇÃO: Adicionando as coordenadas ao mapa para salvar no Firebase
      'latitude': latitude,
      'longitude': longitude,
      'horarios': horarios.map(
        (dia, horario) => MapEntry(dia, horario.toMap()),
      ),
    };
  }

  // ALTERAÇÃO: Adicionando latitude e longitude ao método copyWith
  EstabelecimentoModel copyWith({
    bool? filaAberta,
    int? contagemFila,
    bool? emailVerified,
    double? latitude,
    double? longitude,
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
      emailVerified: emailVerified ?? this.emailVerified,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
