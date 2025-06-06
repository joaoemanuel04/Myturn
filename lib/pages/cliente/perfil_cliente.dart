import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

class PerfilScreen extends StatefulWidget {
  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // --- 1. VARIÁVEIS DE ESTADO ---
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final _formKey = GlobalKey<FormState>();

  // Controllers para os campos editáveis
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  // Variáveis para guardar os dados fixos
  String email = 'Carregando...';
  String dataNascimento = 'Carregando...';

  // Variáveis para controlar a UI
  bool _isLoading = true;
  bool _isEditing = false;

  // --- 2. CICLO DE VIDA (initState, dispose) ---
  @override
  void initState() {
    super.initState();
    // Inicializa os controllers
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _carregarDados();
  }

  @override
  void dispose() {
    // Descarta os controllers para liberar memória
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- 3. FUNÇÕES DE DADOS (carregar, salvar) ---

  Future<void> _carregarDados() async {
    // Usamos o caminho 'users/$uid' que você forneceu no código anterior.
    // Se o seu nó for 'clientes/$uid', apenas troque 'users' por 'clientes' aqui.
    final snapshot = await FirebaseDatabase.instance.ref('users/$uid').get();
    if (snapshot.exists && mounted) {
      final dados = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        // Popula os controllers com os dados do Firebase
        _nameController.text = dados['name'] ?? 'Não informado';
        _phoneController.text = dados['phone'] ?? 'Não informado';
        // Popula as variáveis de texto simples
        email = dados['email'] ?? 'Não informado';
        dataNascimento = dados['birthDate'] ?? 'Não informado';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarAlteracoes() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Cria um mapa apenas com os dados que serão atualizados
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
        // Volta para o modo de visualização
        setState(() => _isEditing = false);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    }
  }

  void _cancelarEdicao() {
    // Recarrega os dados originais para descartar quaisquer alterações não salvas
    _carregarDados();
    setState(() => _isEditing = false);
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  // --- 4. WIDGETS DE UI ---

  // Widget para os campos que NÃO são editáveis
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
              // Se estiver editando, mostra o botão "Cancelar"
              ? TextButton(
                onPressed: _cancelarEdicao,
                child: Text('Cancelar', style: TextStyle(color: Colors.white)),
              )
              // Se estiver visualizando, mostra o botão "Editar"
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
                    // --- CAMPO NOME ---
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing, // Habilita/desabilita a edição
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

                    // --- CAMPO TELEFONE ---
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

                    // --- CAMPOS NÃO EDITÁVEIS ---
                    _buildInfoTile('Email', email),
                    _buildInfoTile('Data de nascimento', dataNascimento),

                    SizedBox(height: 32),

                    // --- BOTÕES DE AÇÃO ---
                    if (_isEditing) // Mostra o botão Salvar apenas no modo de edição
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
