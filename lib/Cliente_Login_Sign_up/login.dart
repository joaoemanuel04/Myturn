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
import 'package:myturn/services/deep_link_service.dart';
import 'package:myturn/services/fila_service.dart';
import 'package:myturn/pages/cliente/fila_ativa.dart';
import 'package:myturn/services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
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

  Future<void> _handlePostLogin() async {
    await NotificationService().saveTokenToDatabase();
    if (deepLinkService.pendingEstablishmentId != null) {
      final establishmentId = deepLinkService.pendingEstablishmentId!;
      deepLinkService.pendingEstablishmentId = null;

      if (!mounted) return;

      setState(() => isLoading = true);

      final filaResult = await FilaService.entrarNaFila(establishmentId);

      if (!mounted) return;

      setState(() => isLoading = false);

      if (filaResult == "success") {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => FilaAtivaScreen(
                  estabelecimentoId: establishmentId,
                  nomeEstabelecimento: "Carregando...",
                ),
          ),
        );
      } else {
        showSnackBar(context, filaResult);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
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
      await _handlePostLogin();
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
              hintText: "Digite seu email",
              icon: Icons.email,
            ),
            TextFieldInpute(
              ispass: true,
              textEditingController: passwordController,
              hintText: "Digite sua senha",
              icon: Icons.lock,
            ),
            const ForgotPassword(),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : MyButton(onTab: loginUsers, text: "Entrar"),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Não tem uma conta?",
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
                    " Cadastre-se",
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
                    await NotificationService().saveTokenToDatabase();
                    await _handlePostLogin();
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
                  // --- INÍCIO DA CORREÇÃO ---
                  Flexible(
                    // 1. Envolva o Text com Flexible
                    child: const Text(
                      "Continuar com o Google",
                      textAlign:
                          TextAlign.center, // 2. (Opcional) Centralize o texto
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18, // 3. (Opcional) Reduza um pouco a fonte
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // --- FIM DA CORREÇÃO ---
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
