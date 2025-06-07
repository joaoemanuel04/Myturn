// lib/Cliente_Login_Sign_up/login.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:myturn/Cliente_Login_Sign_up/Services/auth.dart';
import 'package:myturn/Cliente_Login_Sign_up/sign_up.dart';
import 'package:myturn/Widget/button.dart';
import 'package:myturn/Widget/snack_bar.dart';
import 'package:myturn/Widget/text_field.dart';
import 'package:myturn/esqueceu_senha/esqueceu_senha.dart';
import 'package:myturn/login_com_google/google_auth.dart';
import 'package:myturn/login_com_google/google_informacoes.dart';
import 'package:myturn/pages/cliente/home_cliente.dart';
// ALTERAÇÃO: Imports necessários
import 'package:myturn/services/deep_link_service.dart';
import 'package:myturn/services/fila_service.dart';
import 'package:myturn/pages/cliente/fila_ativa.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState(); // Renomeado para consistência
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Função para lidar com o fluxo pós-login
  Future<void> _handlePostLogin() async {
    // Verifica se há um ID de estabelecimento pendente (se o deep link levou ao login)
    if (deepLinkService.pendingEstablishmentId != null) {
      final establishmentId = deepLinkService.pendingEstablishmentId!;
      deepLinkService.pendingEstablishmentId = null; // Limpa o ID após usá-lo

      if (!mounted) return; // Garante que o widget ainda está montado

      setState(
        () => isLoading = true,
      ); // Mostra loading enquanto tenta entrar na fila

      // Tenta entrar na fila com o ID do estabelecimento
      final filaResult = await FilaService.entrarNaFila(establishmentId);

      if (!mounted)
        return; // Garante que o widget ainda está montado após a operação assíncrona

      setState(() => isLoading = false); // Esconde loading

      if (filaResult == "success") {
        // Se entrou na fila com sucesso, NAVEGA PARA A HOME E DEPOIS PARA A FILA ATIVA,
        // REMOVENDO TODAS AS ROTAS ANTERIORES.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ), // Rota base: HomeScreen
          (Route<dynamic> route) => false, // Remove todas as rotas anteriores
        );
        // Agora, empilha a FilaAtivaScreen no topo da HomeScreen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => FilaAtivaScreen(
                  estabelecimentoId: establishmentId,
                  nomeEstabelecimento:
                      "Carregando...", // O nome será carregado na tela FilaAtiva
                ),
          ),
        );
      } else {
        // Se houve erro ao entrar na fila, mostra o erro e navega para HomeScreen,
        // REMOVENDO TODAS AS ROTAS ANTERIORES.
        showSnackBar(context, filaResult);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ), // Rota base: HomeScreen
          (Route<dynamic> route) => false, // Remove todas as rotas anteriores
        );
      }
    } else {
      // Se não há deep link pendente, apenas navega para HomeScreen,
      // REMOVENDO TODAS AS ROTAS ANTERIORES.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ), // Rota base: HomeScreen
        (Route<dynamic> route) => false, // Remove todas as rotas anteriores
      );
    }
  }

  void loginUsers() async {
    setState(() => isLoading = true);
    String res = await AuthServicews().loginUser(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
    setState(() => isLoading = false);

    if (res == "success") {
      await _handlePostLogin(); // Chama a função para lidar com a navegação pós-login
    } else {
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          children: [
            Image.asset("assets/images/logo.png", height: 150),
            const SizedBox(height: 30),
            TextFieldInpute(
              textEditingController: emailController,
              hintText: "Enter your email",
              icon: Icons.email,
            ),
            TextFieldInpute(
              ispass: true,
              textEditingController: passwordController,
              hintText: "Enter your password",
              icon: Icons.lock,
            ),
            const ForgotPassword(),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : MyButton(onTab: loginUsers, text: "Log In"),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Dont't have an accunt?",
                  style: TextStyle(fontSize: 16),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    " SignUp",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              onPressed: () async {
                setState(() => isLoading = true);
                User? user = await FirebaseServices().signInWithGoogle();
                setState(() => isLoading = false);

                if (!mounted) return;

                if (user != null) {
                  final ref = FirebaseDatabase.instance.ref(
                    'users/${user.uid}',
                  );
                  final snapshot = await ref.get();

                  if (!mounted) return;

                  if (!snapshot.exists) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                GoogleExtraInfoScreen(email: user.email ?? ''),
                      ),
                    );
                  } else {
                    await _handlePostLogin(); // Chama para lidar com a navegação pós-login
                  }
                } else {
                  showSnackBar(context, "Erro ao fazer login com Google");
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Image.network(
                      "https://ouch-cdn2.icons8.com/VGHyfDgzIiyEwg3RIll1nYupfj653vnEPRLr0AeoJ8g/rs:fit:456:456/czM6Ly9pY29uczgu/b3VjaC1wcm9kLmFz/c2V0cy9wbmcvODg2/LzRjNzU2YThjLTQx/MjgtNGZlZS04MDNl/LTAwMTM0YzEwOTMy/Ny5wbmc.png",
                      height: 35,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Continue with Google",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
