import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthServicews {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<String> signUpUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String birthDate,
  }) async {
    String res = "Ocorreu um erro inesperado. Tente novamente.";
    try {
      if (email.isEmpty ||
          password.isEmpty ||
          name.isEmpty ||
          phone.isEmpty ||
          birthDate.isEmpty) {
        return "Preencha todos os campos!";
      }

      // Cria usuário
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await prefs.setString('phone', phone);
      await prefs.setString('birthDate', birthDate);

      // Envia email de verificação
      await credential.user!.sendEmailVerification();

      // Aguarda verificação manual
      await _auth.signOut();

      res = "success";
    } on FirebaseAuthException catch (e) {
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
          res = "Erro ao registrar: ${e.message}";
          break;
      }
    } catch (e) {
      res = "Erro inesperado: $e";
    }
    return res;
  }

  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Ocorreu um erro inesperado. Tente novamente.";
    try {
      if (email.isEmpty || password.isEmpty) {
        return "Por favor, preencha todos os campos.";
      }

      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        return "Por favor, verifique seu email antes de fazer login.";
      }

      // Salva os dados apenas após a verificação do e-mail
      final snapshot = await _dbRef.child("users").child(cred.user!.uid).get();
      if (!snapshot.exists) {
        final prefs = await SharedPreferences.getInstance();
        final name = prefs.getString('name') ?? "";
        final phone = prefs.getString('phone') ?? "";
        final birthDate = prefs.getString('birthDate') ?? "";

        await _dbRef.child("users").child(cred.user!.uid).set({
          "name": name,
          "email": cred.user!.email,
          "phone": phone,
          "birthDate": birthDate,
          "uid": cred.user!.uid,
          "emailVerified": true,
        });

        // Limpa os dados locais após salvar no banco
        await prefs.remove('name');
        await prefs.remove('phone');
        await prefs.remove('birthDate');
      }

      res = "success";
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          res = "Usuário não encontrado.";
          break;
        case 'wrong-password':
          res = "Senha incorreta.";
          break;
        case 'invalid-email':
          res = "E-mail inválido.";
          break;
        default:
          res = "Erro ao fazer login: ${e.message}";
          break;
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
