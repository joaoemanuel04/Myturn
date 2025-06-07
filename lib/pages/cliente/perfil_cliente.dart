import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:myturn/models/user_model.dart'; // ALTERAÇÃO: Import do model

class PerfilScreen extends StatefulWidget {
  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  String email = 'Carregando...';
  String dataNascimento = 'Carregando...';

  bool _isLoading = true;
  bool _isEditing = false;

  // ALTERAÇÃO: Adicionada uma variável para o objeto do usuário
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _carregarDados();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    if (mounted) setState(() => _isLoading = true);
    final snapshot = await FirebaseDatabase.instance.ref('users/$uid').get();
    if (snapshot.exists && mounted) {
      // ALTERAÇÃO: Conversão para o objeto UserModel
      _user = UserModel.fromMap(
        Map<String, dynamic>.from(snapshot.value as Map),
      );

      setState(() {
        _nameController.text = _user!.name;
        _phoneController.text = _user!.phone;
        email = _user!.email;
        dataNascimento = _user!.birthDate;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (_formKey.currentState?.validate() ?? false) {
      final dadosParaAtualizar = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      try {
        await FirebaseDatabase.instance
            .ref('users/$uid')
            .update(dadosParaAtualizar);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
        setState(() => _isEditing = false);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    }
  }

  void _cancelarEdicao() {
    // Recarrega os dados originais a partir do objeto _user
    if (_user != null) {
      _nameController.text = _user!.name;
      _phoneController.text = _user!.phone;
    }
    setState(() => _isEditing = false);
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed('/');
  }

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
      subtitle: Text(value, style: TextStyle(fontSize: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meu Perfil'),
        actions: [
          _isEditing
              ? TextButton(
                onPressed: _cancelarEdicao,
                child: Text('Cancelar', style: TextStyle(color: Colors.white)),
              )
              : IconButton(
                icon: Icon(Icons.edit),
                tooltip: 'Editar Perfil',
                onPressed: () => setState(() => _isEditing = true),
              ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        border:
                            _isEditing
                                ? UnderlineInputBorder()
                                : InputBorder.none,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'Telefone',
                        border:
                            _isEditing
                                ? UnderlineInputBorder()
                                : InputBorder.none,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(fontSize: 18),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TelefoneInputFormatter(),
                      ],
                    ),
                    Divider(height: 32),
                    _buildInfoTile('Email', email),
                    _buildInfoTile('Data de nascimento', dataNascimento),
                    SizedBox(height: 32),
                    if (_isEditing)
                      ElevatedButton(
                        onPressed: _salvarAlteracoes,
                        child: Text('Salvar Alterações'),
                      ),
                    TextButton(
                      onPressed: _logout,
                      child: Text('Sair da conta'),
                    ),
                  ],
                ),
              ),
    );
  }
}
