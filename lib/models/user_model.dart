class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String birthDate;
  final bool emailVerified;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.birthDate,
    this.emailVerified = false,
  });

  // Converte um Map (geralmente vindo do Firebase) para um objeto UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'Nome não informado',
      email: map['email'] ?? 'E-mail não informado',
      phone: map['phone'] ?? 'Telefone não informado',
      birthDate: map['birthDate'] ?? 'Data não informada',
      emailVerified: map['emailVerified'] ?? false,
    );
  }

  // Converte o objeto UserModel para um Map para salvar no Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'birthDate': birthDate,
      'emailVerified': emailVerified,
    };
  }
}
