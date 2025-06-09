// lib/esqueceu_senha/esqueceu_senha.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myturn/Widget/snack_bar.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  TextEditingController emailController = TextEditingController();
  final auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: () {
            myDialogBox(context);
          },
          child: const Text(
            "Esqueceu a senha?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  void myDialogBox(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(),
                    const Text(
                      "Esqueceu sua senha?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Digite o Email",
                    hintText: "ex: abc@gmail.com",
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () async {
                    if (emailController.text.trim().isEmpty) {
                      showSnackBar(context, "Por favor, digite seu e-mail.");
                      return;
                    }
                    try {
                      await auth.sendPasswordResetEmail(
                        email: emailController.text.trim(),
                      );
                      showSnackBar(
                        context,
                        "Link para redefinição de senha enviado para o seu e-mail.",
                      );
                    } catch (error) {
                      showSnackBar(
                        context,
                        "Erro ao enviar e-mail. Verifique o endereço e tente novamente.",
                      );
                    }

                    Navigator.pop(context);
                    emailController.clear();
                  },
                  child: const Text(
                    "Enviar",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
