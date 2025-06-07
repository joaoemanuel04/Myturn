// lib/Cliente_Login_Sign_up/Services/auth.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:myturn/models/user_model.dart';

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

      // 1. Cria o usuário na autenticação do Firebase
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. ALTERAÇÃO: Removemos SharedPreferences e criamos o objeto UserModel imediatamente
      final newUser = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        birthDate: birthDate,
        emailVerified: false, // O cadastro começa com 'false'
      );

      // 3. ALTERAÇÃO: Salva o objeto completo no banco de dados
      await _dbRef
          .child("users")
          .child(credential.user!.uid)
          .set(newUser.toMap());

      // 4. Envia o e-mail de verificação
      await credential.user!.sendEmailVerification();

      // 5. Desloga o usuário para forçá-lo a fazer login após verificar
      await _auth.signOut();

      res = "success";
    } on FirebaseAuthException catch (e) {
      // (código de tratamento de erro inalterado)
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

      // ALTERAÇÃO: Checagem principal aqui!
      if (!cred.user!.emailVerified) {
        await _auth.signOut(); // Garante que o usuário não fique logado
        return "Por favor, verifique seu email antes de fazer login. Cheque sua caixa de entrada e spam.";
      }

      // ALTERAÇÃO: Se o email está verificado, atualizamos nosso banco de dados se necessário.
      final userRef = _dbRef.child("users").child(cred.user!.uid);
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        await _auth.signOut(); // Desloga o usuário por segurança
        return "Este e-mail não pertence a uma conta de cliente.";
      }

      // Se o usuário é um cliente, continuamos com a lógica que já existia
      final userData = UserModel.fromMap(
        Map<String, dynamic>.from(snapshot.value as Map),
      );
      if (!userData.emailVerified) {
        await userRef.update({'emailVerified': true});
      }

      res = "success";
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential': // Novo código de erro do Firebase para login inválido
          res = "E-mail ou senha inválidos.";
          break;
        case 'wrong-password':
          res = "E-mail ou senha inválidos.";
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
