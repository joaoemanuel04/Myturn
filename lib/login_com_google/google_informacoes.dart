import 'package:brasil_fields/brasil_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myturn/Cliente_Login_Sign_up/Success.dart';
import 'package:myturn/Widget/button.dart';
import 'package:myturn/Widget/snack_bar.dart';
import 'package:myturn/Widget/text_field.dart';

class GoogleExtraInfoScreen extends StatefulWidget {
  final String email;

  const GoogleExtraInfoScreen({super.key, required this.email});

  @override
  State<GoogleExtraInfoScreen> createState() => _GoogleExtraInfoScreenState();
}

class _GoogleExtraInfoScreenState extends State<GoogleExtraInfoScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  bool isLoading = false;

  Future<void> saveInfoToDatabase() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showSnackBar(context, "Usuário não autenticado.");
      return;
    }

    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        birthDateController.text.isEmpty) {
      showSnackBar(context, "Preencha todos os campos!");
      return;
    }

    setState(() => isLoading = true);

    try {
      final ref = FirebaseDatabase.instance.ref().child('users/${user.uid}');

      await ref.set({
        'nome': nameController.text.trim(),
        'email': widget.email,
        'telefone': phoneController.text.trim(),
        'data_nascimento': birthDateController.text.trim(),
        'uid': user.uid,
      });

      setState(() => isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SuccessScreen()),
      );
    } catch (e) {
      setState(() => isLoading = false);
      showSnackBar(context, 'Erro ao salvar dados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete seu cadastro")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            TextFieldInpute(
              textEditingController: nameController,
              hintText: "Nome completo",
              icon: Icons.person,
            ),
            TextFieldInpute(
              textEditingController: phoneController,
              hintText: "Celular",
              icon: Icons.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TelefoneInputFormatter(),
              ],
            ),
            TextFieldInpute(
              textEditingController: birthDateController,
              hintText: "Data de Nascimento",
              icon: Icons.cake,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                DataInputFormatter(),
              ],
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : MyButton(
                  onTab: saveInfoToDatabase,
                  text: "Finalizar cadastro",
                ),
          ],
        ),
      ),
    );
  }
}
