//Editar Perfil
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:myturn/Widget/text_field.dart';

class EditarPerfilScreen extends StatefulWidget {
  @override
  _EditarPerfilScreenState createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  String nome = '';
  String telefone = '';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    nome = nameController.text.trim();
    telefone = phoneController.text.trim();
    final snapshot = await FirebaseDatabase.instance.ref('users/$uid').get();
    if (snapshot.exists) {
      final dados = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        nome = dados['name'] ?? '';
        telefone = dados['phone'] ?? '';
      });
    }
  }

  Future<void> salvarAlteracoes() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseDatabase.instance.ref('users/$uid').update({
        'name': nome,
        'phone': telefone,
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dados atualizados com sucesso')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: salvarAlteracoes,
                child: Text('Salvar Alterações'),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
