import 'package:flutter/material.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/estabelecimento_sign_up.dart';
import 'package:myturn/Widget/button.dart';
import 'package:myturn/Widget/text_field.dart';
import 'package:myturn/Widget/snack_bar.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/Services/estabelecimento_auth.dart';

class EstabelecimentoLoginScreen extends StatefulWidget {
  const EstabelecimentoLoginScreen({super.key});

  @override
  State<EstabelecimentoLoginScreen> createState() =>
      _EstabelecimentoLoginScreenState();
}

class _EstabelecimentoLoginScreenState
    extends State<EstabelecimentoLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void loginEstabelecimento() async {
    setState(() {
      isLoading = true;
    });

    String res = await EstabelecimentoAuthService().loginEstabelecimento(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (res == "success") {
      showSnackBar(context, "Login realizado com sucesso!");
      // Navegue para a tela principal do estabelecimento aqui, se desejar
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
                child: Image.asset("assets/images/logo.png"),
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
                onTab: loginEstabelecimento,
                text: isLoading ? "Carregando..." : "Entrar",
              ),
              SizedBox(height: height / 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Não tem uma conta? ",
                    style: TextStyle(fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const EstabelecimentoSignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Cadastre-se",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
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
