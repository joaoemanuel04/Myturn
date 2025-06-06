import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Para formatar a hora

// --- 1. MODELO DE DADOS ---
// É uma boa prática criar uma classe para representar seus dados.
// Isso torna o código mais limpo e seguro do que usar Maps.
class ClienteNaFila {
  final String uid;
  final String nome;
  final DateTime horaEntrada;

  ClienteNaFila({
    required this.uid,
    required this.nome,
    required this.horaEntrada,
  });

  factory ClienteNaFila.fromSnapshot(DataSnapshot snapshot) {
    final map = Map<String, dynamic>.from(snapshot.value as Map);
    return ClienteNaFila(
      uid: snapshot.key!,
      nome: map['nome'] ?? 'Cliente anônimo',
      horaEntrada:
          DateTime.tryParse(map['horaEntrada'] ?? '') ?? DateTime.now(),
    );
  }
}

// --- 2. A TELA PRINCIPAL (WIDGET) ---
class EstabelecimentoHomeScreen extends StatefulWidget {
  const EstabelecimentoHomeScreen({super.key});

  @override
  State<EstabelecimentoHomeScreen> createState() =>
      _EstabelecimentoHomeScreenState();
}

class _EstabelecimentoHomeScreenState extends State<EstabelecimentoHomeScreen> {
  // --- 3. VARIÁVEIS DE ESTADO E REFERÊNCIAS ---
  final _auth = FirebaseAuth.instance;
  late final DatabaseReference _estabelecimentoRef;
  late final DatabaseReference _filaRef;

  StreamSubscription? _filaSubscription;
  StreamSubscription? _statusFilaSubscription;

  List<ClienteNaFila> _fila = [];
  bool _isFilaAberta = false;
  bool _isLoading = true;
  int _atendidosHoje = 0; // Contador simples para o dashboard

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  @override
  void dispose() {
    // É ESSENCIAL cancelar os ouvintes para evitar vazamentos de memória.
    _filaSubscription?.cancel();
    _statusFilaSubscription?.cancel();
    super.dispose();
  }

  // --- 4. LÓGICA DE NEGÓCIO E FIREBASE ---

  void _inicializarDados() {
    final user = _auth.currentUser;
    if (user == null) {
      // Se por algum motivo não houver usuário logado, volta para a tela de login.
      // Adicione sua lógica de navegação de logout aqui.
      return;
    }

    // Define as referências principais do Firebase com base no UID do estabelecimento
    _estabelecimentoRef = FirebaseDatabase.instance.ref(
      'estabelecimentos/${user.uid}',
    );
    _filaRef = FirebaseDatabase.instance.ref('filas/${user.uid}/clientes');

    _escutarStatusDaFila();
    _escutarMudancasDaFila();
  }

  void _escutarStatusDaFila() {
    // Ouve em tempo real se a fila está aberta ou fechada
    _statusFilaSubscription = _estabelecimentoRef
        .child('filaAberta')
        .onValue
        .listen((event) {
          if (mounted) {
            setState(() {
              _isFilaAberta = (event.snapshot.value as bool?) ?? false;
              _isLoading = false; // A primeira carga de dados terminou
            });
          }
        });
  }

  void _escutarMudancasDaFila() {
    // Ouve em tempo real as mudanças na lista de clientes
    _filaSubscription = _filaRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final novaFila =
            data.entries.map((e) {
              // Reutiliza o factory constructor do nosso modelo
              return ClienteNaFila.fromSnapshot(e.value);
            }).toList();

        // Ordena pela hora de entrada para garantir a ordem correta
        novaFila.sort((a, b) => a.horaEntrada.compareTo(b.horaEntrada));

        if (mounted) {
          setState(() {
            _fila = novaFila;
          });
        }
      } else {
        // Se o nó 'clientes' não existe, a fila está vazia
        if (mounted) {
          setState(() {
            _fila = [];
          });
        }
      }
    });
  }

  Future<void> _alternarStatusFila(bool novoStatus) async {
    try {
      await _estabelecimentoRef.child('filaAberta').set(novoStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(novoStatus ? 'Fila Aberta!' : 'Fila Fechada!'),
            backgroundColor: novoStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      _mostrarErro("Erro ao alterar status da fila.");
    }
  }

  Future<void> _removerCliente(String clienteUid) async {
    // Referências para os nós que precisam ser deletados
    final clienteNaFilaRef = _filaRef.child(clienteUid);
    final clienteNaReservaRef = FirebaseDatabase.instance.ref(
      'minhasReservasPorUsuario/$clienteUid/${_auth.currentUser!.uid}',
    );

    try {
      // Remove ambos em paralelo para otimizar
      await Future.wait([
        clienteNaFilaRef.remove(),
        clienteNaReservaRef.remove(),
      ]);
    } catch (e) {
      _mostrarErro("Erro ao remover cliente.");
    }
  }

  Future<void> _chamarProximoCliente() async {
    if (_fila.isEmpty) return;

    final proximoCliente = _fila.first;
    await _removerCliente(proximoCliente.uid);

    if (mounted) {
      setState(() {
        _atendidosHoje++; // Incrementa o contador local
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${proximoCliente.nome} foi chamado(a)!')),
      );
    }
  }

  void _mostrarErro(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
      );
    }
  }

  // --- 5. CONSTRUÇÃO DA INTERFACE (UI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Painel de Controle'),
        actions: [
          // Lógica para o menu de opções
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'perfil') {
                // Navegue para a tela de editar perfil do estabelecimento
                // Navigator.pushNamed(context, '/estabelecimento/perfil');
              } else if (value == 'sair') {
                _auth.signOut();
                // Navegue de volta para a tela de login
                // Navigator.pushReplacementNamed(context, '/');
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'perfil',
                    child: Text('Editar Perfil'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sair',
                    child: Text('Sair'),
                  ),
                ],
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildControleFila(),
                    const SizedBox(height: 16),
                    _buildDashboard(),
                    const SizedBox(height: 16),
                    const Text(
                      'Fila de Espera',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Expanded(child: _buildListaFila()),
                  ],
                ),
              ),
      // O botão principal fica "flutuando" na parte de baixo para fácil acesso
      bottomNavigationBar: _buildBotaoChamarProximo(),
    );
  }

  // --- 6. WIDGETS AUXILIARES PARA ORGANIZAR O CÓDIGO ---

  Widget _buildControleFila() {
    return Card(
      elevation: 2,
      child: SwitchListTile(
        title: Text(
          'Status da Fila',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _isFilaAberta
              ? 'Aberta para novos clientes'
              : 'Fechada para novos clientes',
        ),
        value: _isFilaAberta,
        onChanged: _alternarStatusFila,
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildDashboard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetrica('Pessoas na Fila', _fila.length.toString()),
            _buildMetrica('Atendidos Hoje', _atendidosHoje.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildMetrica(String titulo, String valor) {
    return Column(
      children: [
        Text(
          titulo,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildListaFila() {
    if (_fila.isEmpty) {
      return const Center(
        child: Text(
          'A fila está vazia.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _fila.length,
      itemBuilder: (context, index) {
        final cliente = _fila[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(child: Text((index + 1).toString())),
            title: Text(
              cliente.nome,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Entrou às: ${DateFormat('HH:mm').format(cliente.horaEntrada)}',
            ),
            trailing: IconButton(
              icon: Icon(Icons.person_remove, color: Colors.red.shade400),
              tooltip: 'Remover da fila',
              onPressed: () {
                // Adiciona um diálogo de confirmação para evitar remoção acidental
                showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: Text('Confirmar Remoção'),
                        content: Text(
                          'Deseja remover ${cliente.nome} da fila?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              _removerCliente(cliente.uid);
                              Navigator.of(ctx).pop();
                            },
                            child: Text(
                              'Remover',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBotaoChamarProximo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.campaign),
        label: const Text('CHAMAR PRÓXIMO'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // O botão é desabilitado se a fila estiver vazia
        onPressed: _fila.isEmpty ? null : _chamarProximoCliente,
      ),
    );
  }
}
