import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:myturn/Cliente_Login_Sign_up/Services/auth.dart';
import 'package:myturn/Cliente_Login_Sign_up/Success.dart';
import 'package:myturn/Cliente_Login_Sign_up/sign_up.dart';
import 'package:myturn/Widget/button.dart';
import 'package:myturn/Widget/snack_bar.dart';
import 'package:myturn/Widget/text_field.dart';
import 'package:myturn/esqueceu_senha/esqueceu_senha.dart';
import 'package:myturn/login_com_google/google_auth.dart';
import 'package:myturn/login_com_google/google_informacoes.dart';
import 'package:myturn/pages/cliente/home_cliente.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void loginUsers() async {
    String res = await AuthServicews().loginUser(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (res == "success") {
      setState(() {
        isLoading = true;
      });
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
    } else {
      setState(() {
        isLoading = false;
      });
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
            const SizedBox(height: 10), // Espaçamento antes do botão do Google
            // ### BOTÃO DO GOOGLE ATUALIZADO EXATAMENTE COMO VOCÊ PEDIU ###
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              onPressed: () async {
                User? user = await FirebaseServices().signInWithGoogle();
                // A verificação 'if (mounted)' garante que o contexto ainda é válido
                // após a operação assíncrona, evitando erros.
                if (mounted) {
                  if (user != null) {
                    final ref = FirebaseDatabase.instance.ref(
                      'users/${user.uid}',
                    );
                    final snapshot = await ref.get();

                    // Verifica novamente se o widget ainda está montado
                    if (mounted) {
                      if (!snapshot.exists) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => GoogleExtraInfoScreen(
                                  email: user.email ?? '',
                                ),
                          ),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    }
                  } else {
                    showSnackBar(context, "Erro ao fazer login com Google");
                  }
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
