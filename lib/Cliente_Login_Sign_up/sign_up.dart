import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myturn/Cliente_Login_Sign_up/Services/auth.dart';
import 'package:myturn/Cliente_Login_Sign_up/Success.dart';
import 'package:myturn/Cliente_Login_Sign_up/login.dart';
import 'package:myturn/Widget/button.dart';
import 'package:myturn/Widget/snack_bar.dart';
import 'package:myturn/Widget/text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
  }

  void signUpUser() async {
    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      showSnackBar(context, "As senhas não conferem!");
      return;
    }

    setState(() => isLoading = true);

    String res = await AuthServicews().signUpUser(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      birthDate: birthDateController.text.trim(),
    );

    setState(() => isLoading = false);

    if (res == "success") {
      showSnackBar(
        context,
        "Cadastro realizado! Verifique seu email para ativar a conta.",
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SuccessScreen()),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: height / 3,
                child: Image.asset("assets/images/sign.jpg"),
              ),
              TextFieldInpute(
                textEditingController: nameController,
                hintText: "Nome completo",
                icon: Icons.person,
              ),
              TextFieldInpute(
                textEditingController: phoneController,
                hintText: "Celular (ex: (99) 99999-9999)",
                icon: Icons.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TelefoneInputFormatter(),
                ],
              ),
              TextFieldInpute(
                textEditingController: birthDateController,
                hintText: "Data de Nascimento (dd/mm/aaaa)",
                icon: Icons.cake,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  DataInputFormatter(),
                ],
              ),
              TextFieldInpute(
                textEditingController: emailController,
                hintText: "Email",
                icon: Icons.email,
              ),
              TextFieldInpute(
                textEditingController: passwordController,
                hintText: "Senha",
                ispass: true,
                icon: Icons.lock,
              ),
              TextFieldInpute(
                textEditingController: confirmPasswordController,
                hintText: "Confirme a senha",
                ispass: true,
                icon: Icons.lock_outline,
              ),

              isLoading
                  ? const CircularProgressIndicator()
                  : MyButton(onTab: signUpUser, text: "Cadastrar"),
              SizedBox(height: height / 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Já tem uma conta?"),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
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
