import 'package:flutter/material.dart';
import 'package:myturn/Cliente_Login_Sign_up/login.dart';
import 'package:myturn/Widget/button.dart';
import 'package:myturn/Widget/text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
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
                child: Image.asset("imagens/sign.jpg"),
              ),
              TextFieldInpute(
                textEditingController: emailController,
                hintText: "Enter your name",
                icon: Icons.person,
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
              MyButton(onTab: () {}, text: "Sign Up"),
              SizedBox(height: height / 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: Text(
                      " Login",
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
