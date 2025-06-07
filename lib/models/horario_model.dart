class HorarioModel {
  final String inicio;
  final String fim;
  final bool fechado;
  final bool vinteQuatroHoras;

  HorarioModel({
    required this.inicio,
    required this.fim,
    required this.fechado,
    required this.vinteQuatroHoras,
  });

  factory HorarioModel.fromMap(Map<String, dynamic> map) {
    return HorarioModel(
      inicio: map['inicio'] ?? '',
      fim: map['fim'] ?? '',
      fechado: map['fechado'] ?? false,
      vinteQuatroHoras: map['vinteQuatroHoras'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inicio': inicio,
      'fim': fim,
      'fechado': fechado,
      'vinteQuatroHoras': vinteQuatroHoras,
    };
  }
}
