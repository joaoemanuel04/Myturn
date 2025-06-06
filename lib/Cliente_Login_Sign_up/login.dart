import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:myturn/Cliente_Login_Sign_up/Services/auth.dart';
import 'package:myturn/Cliente_Login_Sign_up/sign_up.dart';
import 'package:myturn/Widget/snack_bar.dart';
import 'package:myturn/Widget/text_field.dart';
import 'package:myturn/esqueceu_senha/esqueceu_senha.dart';
import 'package:myturn/login_com_google/google_auth.dart';
import 'package:myturn/login_com_google/google_informacoes.dart';
import 'package:myturn/pages/cliente/home_cliente.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  // Lógica de login com E-mail e Senha
  Future<void> _loginUser() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) showSnackBar(context, "Sem conexão com a internet.");
      return;
    }

    setState(() => isLoading = true);

    try {
      String res = await AuthServicews().loginUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (res == "success" && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        if (mounted) showSnackBar(context, res);
      }
    } catch (e) {
      if (mounted)
        showSnackBar(context, "Ocorreu um erro inesperado. Tente novamente.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Lógica de login com Google (agora implementada)
  Future<void> _googleSignIn() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) showSnackBar(context, "Sem conexão com a internet.");
      return;
    }

    setState(() => isLoading = true);
    try {
      User? user = await FirebaseServices().signInWithGoogle();

      if (user != null && mounted) {
        // Verifica se o usuário já existe no banco de dados
        final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
        final snapshot = await userRef.get();

        if (snapshot.exists) {
          // Usuário já existe, vai para a home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // Primeiro login com Google, pede informações extras
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GoogleExtraInfoScreen(email: user.email!),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) showSnackBar(context, "Erro ao fazer login com Google.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),

              const _LoginHeader(),

              SizedBox(height: MediaQuery.of(context).size.height * 0.08),

              // Formulário
              TextFieldInpute(
                textEditingController: emailController,
                hintText: "Seu e-mail",
                icon: Icons.alternate_email,
              ),
              const SizedBox(height: 16),
              TextFieldInpute(
                ispass: true,
                textEditingController: passwordController,
                hintText: "Sua senha",
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: 12),
              const ForgotPassword(),
              const SizedBox(height: 24),

              // Botões de Ação
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _loginUser,
                      child: const Text('Entrar'),
                    ),
                    const SizedBox(height: 20),
                    const _OrDivider(),
                    const SizedBox(height: 20),
                    _GoogleSignInButton(onPressed: _googleSignIn),
                  ],
                ),

              const SizedBox(height: 30),

              const _SignUpLink(),
            ],
          ),
        ),
      ),
    );
  }
}

// WIDGETS PRIVADOS E OTIMIZADOS (STATeless e CONST)

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Bem-vindo de volta!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Faça login para continuar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(endIndent: 10)),
        Text("OU", style: TextStyle(color: Colors.grey)),
        Expanded(child: Divider(indent: 10)),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Image.asset('assets/images/google_icon.png', height: 24.0),
      label: const Text(
        'Continuar com Google',
        style: TextStyle(color: Colors.black87),
      ),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}

class _SignUpLink extends StatelessWidget {
  const _SignUpLink();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Não tem uma conta?",
          style: TextStyle(color: Colors.black54),
        ),
        TextButton(
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              ),
          child: Text(
            "Cadastre-se",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
