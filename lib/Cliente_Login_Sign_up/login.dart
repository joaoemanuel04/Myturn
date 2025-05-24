import 'package:flutter/material.dart';
import 'package:myturn/Cliente_Login_Sign_up/sign_up.dart';
import 'package:myturn/Widget/button.dart';
import 'package:myturn/Widget/text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
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
                child: Image.asset("imagens/logo.jpg"),
              ),
              TextFieldInpute(
                textEditingController: emailController,
                hintText: "Enter your email",
                icon: Icons.email,
              ),
              TextFieldInpute(
                textEditingController: passwordController,
                hintText: "Enter your password",
                icon: Icons.lock,
              ),
              const Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Esqueceu a senha?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              MyButton(onTab: () {}, text: "Log In"),
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
            ],
          ),
        ),
      ),
    );
  }
}
