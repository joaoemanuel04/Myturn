import 'package:flutter/material.dart';
// 1. ADICIONE ESTE IMPORT PARA A TELA HOME QUE CRIAMOS
import 'package:myturn/pages/estabelecimento/estabelecimento_home_screen.dart';
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

    if (res == "success") {
      if (!mounted) return; // Verificação de segurança

      // 2. SUBSTITUA O showSnackBar PELA NAVEGAÇÃO
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const EstabelecimentoHomeScreen(),
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        // Verificação de segurança
        showSnackBar(context, res);
      }
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
                ispass: true, // Adicionado para esconder a senha
                icon: Icons.lock,
              ),
              // ... o resto do seu widget de "Esqueceu a senha?"
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
