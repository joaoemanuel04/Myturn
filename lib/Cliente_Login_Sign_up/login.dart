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
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: height / 2.7,
                child: Image.asset("assets/images/logo.png"),
              ),
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
              MyButton(onTab: loginUsers, text: "Log In"),
              SizedBox(height: height / 15),
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
                    child: Text(
                      " SignUp",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 10,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                  ),
                  onPressed: () async {
                    User? user = await FirebaseServices().signInWithGoogle();
                    if (user != null) {
                      // Referência no Realtime Database para o usuário
                      final ref = FirebaseDatabase.instance.ref(
                        'users/${user.uid}',
                      );

                      final snapshot = await ref.get();

                      if (!snapshot.exists) {
                        // Se não existe cadastro, vai para tela de info extra
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
                        // Se já existe cadastro, vai direto para SuccessScreen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SuccessScreen(),
                          ),
                        );
                      }
                    } else {
                      // Opcional: mostrar erro se login falhar
                      showSnackBar(context, "Erro ao fazer login com Google");
                    }
                  },
                  child: Row(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
