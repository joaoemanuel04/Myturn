import 'package:flutter/material.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/Services/estabelecimento_auth.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/estabelecimento_success.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/estabelecimento_login.dart';
import 'package:myturn/Widget/button.dart';
import 'package:myturn/Widget/snack_bar.dart';
import 'package:myturn/Widget/text_field.dart';

class EstabelecimentoSignUpScreen extends StatefulWidget {
  const EstabelecimentoSignUpScreen({super.key});

  @override
  State<EstabelecimentoSignUpScreen> createState() =>
      _EstabelecimentoSignUpScreenState();
}

class _EstabelecimentoSignUpScreenState
    extends State<EstabelecimentoSignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;

  void signUpEstabelecimento() async {
    setState(() {
      isLoading = true;
    });

    String res = await EstabelecimentoAuthService().signUpEstabelecimento(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      name: nameController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (res == "success") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const EstabelecimentoSuccessScreen(),
        ),
      );
    } else {
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
                child: Image.asset("assets/images/estabelecimento.png"),
              ),
              TextFieldInpute(
                textEditingController: nameController,
                hintText: "Nome do estabelecimento",
                icon: Icons.store,
              ),
              TextFieldInpute(
                textEditingController: emailController,
                hintText: "Digite seu email",
                icon: Icons.email,
              ),
              TextFieldInpute(
                textEditingController: passwordController,
                hintText: "Digite sua senha",
                icon: Icons.lock,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 35),
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
              MyButton(
                onTab: signUpEstabelecimento,
                text: isLoading ? "Carregando..." : "Cadastrar",
              ),
              SizedBox(height: height / 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Já tem uma conta?",
                    style: TextStyle(fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const EstabelecimentoLoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      " Entrar",
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
