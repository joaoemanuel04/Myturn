import 'package:flutter/material.dart';
// 1. ADICIONE ESTE IMPORT PARA A TELA HOME QUE CRIAMOS
import 'package:myturn/pages/estabelecimento/estabelecimento_home_screen.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/estabelecimento_sign_up.dart';
import 'package:myturn/Widget/button.dart';
import 'package:myturn/Widget/text_field.dart';
import 'package:myturn/Widget/snack_bar.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/Services/estabelecimento_auth.dart';
import 'package:myturn/esqueceu_senha/esqueceu_senha.dart';

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
    // A variável 'height' não é mais necessária para o layout principal,
    // mas pode ser mantida se usada em outros lugares.

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // ATUALIZAÇÃO: Trocamos a Column por um ListView.
        // O ListView já é rolável por natureza.
        child: ListView(
          // Adicionamos um padding para que os elementos não fiquem colados nas bordas.
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          children: [
            // Adicionamos um espaço no topo para o layout respirar.
            const SizedBox(height: 30),

            // A imagem agora tem uma altura fixa, o que é mais seguro para o layout.
            Image.asset(
              "assets/images/logo.png",
              height: 150, // Altura fixa em vez de percentual da tela.
            ),
            const SizedBox(height: 40),

            // Seus campos de texto.
            TextFieldInpute(
              textEditingController: emailController,
              hintText: "Digite seu email",
              icon: Icons.email,
            ),
            const SizedBox(height: 20), // Espaçamento entre os campos.
            TextFieldInpute(
              textEditingController: passwordController,
              hintText: "Digite sua senha",
              ispass: true,
              icon: Icons.lock,
            ),
            const SizedBox(height: 24),
            const ForgotPassword(),

            // Seu botão de login.
            MyButton(
              onTab: loginEstabelecimento,
              text: isLoading ? "Carregando..." : "Entrar",
            ),
            const SizedBox(height: 30),

            // Seu link para a tela de cadastro.
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
            // Adicionamos um espaço no final para a rolagem ficar melhor.
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
