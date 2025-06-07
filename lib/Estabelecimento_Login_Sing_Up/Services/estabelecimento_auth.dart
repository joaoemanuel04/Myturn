// lib/Estabelecimento_Login_Sing_Up/Services/estabelecimento_auth.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// ALTERAÇÃO: Imports dos models
import 'package:myturn/models/estabelecimento_model.dart';
import 'package:myturn/models/horario_model.dart';

class EstabelecimentoAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<String> signUpEstabelecimento({
    required String email,
    required String password,
    required String name,
    required String categoria,
    required String cnpj,
    required String celular,
    required String estado,
    required String cidade,
    required Map<String, dynamic>
    horarios, // continua recebendo Map<String, dynamic> da UI
  }) async {
    String res = "Ocorreu um erro inesperado. Tente novamente.";
    try {
      if (email.isEmpty ||
          password.isEmpty ||
          name.isEmpty ||
          categoria.isEmpty ||
          cnpj.isEmpty ||
          celular.isEmpty ||
          estado.isEmpty ||
          cidade.isEmpty ||
          horarios.isEmpty) {
        return "Preencha todos os campos!";
      }

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ALTERAÇÃO: Conversão do mapa de horários da UI para o nosso modelo
      final Map<String, HorarioModel> horariosModel = horarios.map(
        (dia, horarioMap) => MapEntry(dia, HorarioModel.fromMap(horarioMap)),
      );

      // ALTERAÇÃO: Criação do objeto EstabelecimentoModel
      final newEstabelecimento = EstabelecimentoModel(
        uid: cred.user!.uid,
        email: email,
        name: name,
        categoria: categoria,
        cnpj: cnpj,
        celular: celular,
        estado: estado,
        cidade: cidade,
        horarios: horariosModel,
        emailVerified: false, // Começa como false
      );

      // ALTERAÇÃO: Salva o objeto completo no banco de dados
      await _dbRef
          .child("estabelecimentos")
          .child(cred.user!.uid)
          .set(newEstabelecimento.toMap());

      await cred.user!.sendEmailVerification();
      await _auth.signOut();

      res = "success";
    } on FirebaseAuthException catch (e) {
      // (código de erro inalterado)
    } catch (e) {
      res = "Erro inesperado: $e";
    }
    return res;
  }

  Future<String> loginEstabelecimento({
    required String email,
    required String password,
  }) async {
    String res = "Erro ao fazer login.";
    try {
      if (email.isEmpty || password.isEmpty) {
        return "Preencha todos os campos!";
      }

      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ALTERAÇÃO: Checagem principal de verificação de e-mail
      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        return "Verifique seu e-mail antes de fazer login.";
      }

      // ALTERAÇÃO: Atualiza nosso banco de dados se necessário
      final estabRef = _dbRef.child("estabelecimentos").child(cred.user!.uid);
      final snapshot = await estabRef.get();

      if (!snapshot.exists) {
        await _auth.signOut(); // Desloga o usuário por segurança
        return "Este e-mail não pertence a uma conta de estabelecimento.";
      }

      // Se a conta é de um estabelecimento, continuamos a lógica
      final estabData = EstabelecimentoModel.fromMap(
        Map<String, dynamic>.from(snapshot.value as Map),
      );
      if (!estabData.emailVerified) {
        await estabRef.update({'emailVerified': true});
      }

      res = "success";
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential': // Novo código de erro do Firebase
          res = "E-mail ou senha inválidos.";
          break;
        case 'wrong-password':
          res = "E-mail ou senha inválidos.";
          break;
        default:
          res = "Erro: ${e.message}";
      }
    } catch (e) {
      res = "Erro inesperado: $e";
    }
    return res;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
