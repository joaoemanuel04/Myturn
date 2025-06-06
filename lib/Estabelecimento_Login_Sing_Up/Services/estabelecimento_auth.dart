// Imports (adicione a biblioteca de conversão de JSON)
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EstabelecimentoAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // ***** ALTERAÇÃO 1: MUDE A ASSINATURA DO MÉTODO *****
  Future<String> signUpEstabelecimento({
    required String email,
    required String password,
    required String name,
    required String categoria,
    required String cnpj,
    required String celular,
    required String estado,
    required String cidade,
    // Aceita um Map aninhado. Map<String, Map<String, dynamic>>
    required Map<String, dynamic> horarios,
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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await prefs.setString('categoria', categoria);
      await prefs.setString('cnpj', cnpj);
      await prefs.setString('celular', celular);
      await prefs.setString('estado', estado);
      await prefs.setString('cidade', cidade);
      await prefs.setString('uid', cred.user!.uid);

      // ***** ALTERAÇÃO 2: CONVERTA O MAP DE HORÁRIOS PARA UMA STRING JSON *****
      // SharedPreferences só armazena tipos primitivos. jsonEncode transforma o Map em texto.
      String horariosJson = jsonEncode(horarios);
      await prefs.setString('horarios', horariosJson);

      await cred.user!.sendEmailVerification();
      await _auth.signOut();

      res = "success";
    } on FirebaseAuthException catch (e) {
      // ... (seu código de tratamento de erro continua igual)
      switch (e.code) {
        case 'email-already-in-use':
          res = "Este e-mail já está em uso.";
          break;
        case 'invalid-email':
          res = "E-mail inválido.";
          break;
        case 'weak-password':
          res = "A senha deve conter pelo menos 6 caracteres.";
          break;
        default:
          res = "Erro: ${e.message}";
      }
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
      // ... (seu código de verificação de campos continua igual)
      if (email.isEmpty || password.isEmpty) {
        return "Preencha todos os campos!";
      }

      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        return "Verifique seu e-mail antes de fazer login.";
      }

      final snapshot =
          await _dbRef.child("estabelecimentos").child(cred.user!.uid).get();

      if (!snapshot.exists) {
        final prefs = await SharedPreferences.getInstance();

        final Map<String, dynamic> dados = {
          "uid": cred.user!.uid,
          "email": email,
          "name": prefs.getString('name') ?? "",
          "categoria": prefs.getString('categoria') ?? "",
          "cnpj": prefs.getString('cnpj') ?? "",
          "celular": prefs.getString('celular') ?? "",
          "estado": prefs.getString('estado') ?? "",
          "cidade": prefs.getString('cidade') ?? "",
          "emailVerified": true,
        };

        // ***** ALTERAÇÃO 3: LEIA A STRING JSON E CONVERTA DE VOLTA PARA MAP *****
        String horariosJson = prefs.getString('horarios') ?? '{}';
        dados["horarios"] = jsonDecode(
          horariosJson,
        ); // jsonDecode faz o inverso

        await _dbRef.child("estabelecimentos").child(cred.user!.uid).set(dados);

        await prefs.clear();
      }

      res = "success";
    } on FirebaseAuthException catch (e) {
      // ... (seu código de tratamento de erro continua igual)
      switch (e.code) {
        case 'user-not-found':
          res = "Usuário não encontrado.";
          break;
        case 'wrong-password':
          res = "Senha incorreta.";
          break;
        default:
          res = "Erro: ${e.message}";
      }
    } catch (e) {
      res = "Erro inesperado: $e";
    }

    return res;
  }

  // ... (o método signOut continua igual)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
