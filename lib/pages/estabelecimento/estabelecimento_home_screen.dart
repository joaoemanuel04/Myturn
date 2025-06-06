import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

// O modelo de dados para o cliente na fila
class ClienteNaFila {
  final String uid;
  final String nome;
  final DateTime horaEntrada;

  ClienteNaFila({
    required this.uid,
    required this.nome,
    required this.horaEntrada,
  });

  // ERRO 1 CORRIGIDO: Substituído `fromSnapshot` por `fromMap` para simplificar.
  factory ClienteNaFila.fromMap(String uid, Map<String, dynamic> map) {
    return ClienteNaFila(
      uid: uid,
      nome: map['nome'] ?? 'Cliente anônimo',
      horaEntrada:
          DateTime.tryParse(map['horaEntrada'] ?? '') ?? DateTime.now(),
    );
  }
}

// O Widget principal da tela
class EstabelecimentoHomeScreen extends StatefulWidget {
  const EstabelecimentoHomeScreen({super.key});

  @override
  State<EstabelecimentoHomeScreen> createState() =>
      _EstabelecimentoHomeScreenState();
}

class _EstabelecimentoHomeScreenState extends State<EstabelecimentoHomeScreen> {
  // Variáveis de controle e estado
  final _auth = FirebaseAuth.instance;
  late final DatabaseReference _estabelecimentoRef;
  late final DatabaseReference _filaRef;
  late final DatabaseReference _metricasRef;

  StreamSubscription? _filaSubscription;
  StreamSubscription? _statusFilaSubscription;
  StreamSubscription? _metricasSubscription;

  List<ClienteNaFila> _fila = [];
  bool _isFilaAberta = false;
  bool _isLoading = true;
  int _atendidosHoje = 0;

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  @override
  void dispose() {
    // Cancela todos os listeners para evitar vazamentos de memória
    _filaSubscription?.cancel();
    _statusFilaSubscription?.cancel();
    _metricasSubscription?.cancel();
    super.dispose();
  }

  // --- SEÇÃO DE LÓGICA E FIREBASE ---

  void _inicializarDados() {
    final user = _auth.currentUser;
    if (user == null) return;

    _estabelecimentoRef = FirebaseDatabase.instance.ref(
      'estabelecimentos/${user.uid}',
    );
    _filaRef = FirebaseDatabase.instance.ref('filas/${user.uid}/clientes');
    _metricasRef = _estabelecimentoRef.child('metricas');

    _escutarStatusDaFila();
    _escutarMudancasDaFila();
    _escutarMetricas(); // Escuta o contador de atendidos
  }

  void _escutarMetricas() {
    _metricasSubscription = _metricasRef.child('atendidosHoje').onValue.listen((
      event,
    ) {
      if (mounted) {
        setState(() {
          _atendidosHoje = (event.snapshot.value as int?) ?? 0;
        });
      }
    });
  }

  void _escutarStatusDaFila() {
    _statusFilaSubscription = _estabelecimentoRef
        .child('filaAberta')
        .onValue
        .listen((event) {
          if (mounted) {
            setState(() {
              _isFilaAberta = (event.snapshot.value as bool?) ?? false;
              _isLoading = false; // Finaliza o loading inicial
            });
          }
        });
  }

  void _escutarMudancasDaFila() {
    _filaSubscription = _filaRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        // ERRO 1 CORRIGIDO: Usando o novo factory `fromMap`.
        final novaFila =
            data.entries
                .map(
                  (e) => ClienteNaFila.fromMap(
                    e.key,
                    Map<String, dynamic>.from(e.value),
                  ),
                )
                .toList();
        novaFila.sort((a, b) => a.horaEntrada.compareTo(b.horaEntrada));
        if (mounted) setState(() => _fila = novaFila);
      } else {
        // Se não houver clientes, a fila está vazia
        if (mounted) setState(() => _fila = []);
      }
    });
  }

  Future<void> _alternarStatusFila(bool novoStatus) async {
    try {
      await _estabelecimentoRef.child('filaAberta').set(novoStatus);
    } catch (e) {
      _mostrarErro("Erro ao alterar status da fila.");
    }
  }

  Future<void> _removerCliente(String clienteUid) async {
    final clienteNaFilaRef = _filaRef.child(clienteUid);
    final clienteNaReservaRef = FirebaseDatabase.instance.ref(
      'minhasReservasPorUsuario/$clienteUid/${_auth.currentUser!.uid}',
    );
    // ERRO 2 CORRIGIDO: Adicionado Try/Catch para tratar possíveis falhas.
    try {
      // Remove o cliente da fila e da lista de reservas dele em paralelo
      await Future.wait([
        clienteNaFilaRef.remove(),
        clienteNaReservaRef.remove(),
      ]);
    } catch (e) {
      _mostrarErro("Não foi possível remover o cliente.");
    }
  }

  Future<void> _chamarProximoCliente() async {
    if (_fila.isEmpty) return;

    final proximoCliente = _fila.first;

    // Usa uma transação para incrementar o contador no Firebase de forma segura
    final TransactionResult result = await _metricasRef
        .child('atendidosHoje')
        .runTransaction((Object? currentData) {
          int currentValue = (currentData as int?) ?? 0;
          return Transaction.success(currentValue + 1);
        });

    // ERRO 3 CORRIGIDO: Cliente só é removido se a transação for bem-sucedida.
    if (result.committed) {
      await _removerCliente(proximoCliente.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${proximoCliente.nome} foi chamado(a)!')),
        );
      }
    } else {
      _mostrarErro("Falha ao chamar o próximo. Tente novamente.");
    }
  }

  void _mostrarErro(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
      );
    }
  }

  // --- SEÇÃO DE CONSTRUÇÃO DA INTERFACE (UI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.background, // Cor de fundo do tema
      appBar: AppBar(
        title: const Text('Painel de Controle'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              // ERRO 4 CORRIGIDO: `onSelected` agora é async.
              if (value == 'sair') {
                await _auth.signOut();
                if (!mounted) return; // Checagem de segurança
                // Retorna para a tela inicial e remove todas as outras rotas
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
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
              : ListView(
                // Usando ListView para permitir rolagem de todo o conteúdo
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildControleFilaCard(),
                  const SizedBox(height: 24),
                  _buildProximoClienteCard(),
                  const SizedBox(height: 24),
                  _buildMetricasDashboard(),
                  const SizedBox(height: 24),
                  const Text(
                    'Aguardando na Fila',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildFilaDeEsperaList(),
                ],
              ),
    );
  }

  // --- WIDGETS AUXILIARES PARA COMPONENTIZAR A UI ---

  Widget _buildControleFilaCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATUS DA FILA',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isFilaAberta ? 'Aberta' : 'Fechada',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        _isFilaAberta
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                  ),
                ),
              ],
            ),
            Switch(
              value: _isFilaAberta,
              onChanged: _alternarStatusFila,
              activeTrackColor: Colors.green.shade200,
              activeColor: Colors.green.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProximoClienteCard() {
    final proximoCliente = _fila.isNotEmpty ? _fila.first : null;

    return Card(
      elevation: 4,
      color: Theme.of(context).primaryColor, // Cor de destaque do tema
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'PRÓXIMO A SER CHAMADO',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              proximoCliente?.nome ?? 'Ninguém na fila',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (proximoCliente != null)
              Text(
                'Entrou às ${DateFormat('HH:mm').format(proximoCliente.horaEntrada)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('CHAMAR PRÓXIMO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              // O botão fica desabilitado se não houver ninguém na fila
              onPressed: proximoCliente != null ? _chamarProximoCliente : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricasDashboard() {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            titulo: 'Na Fila',
            valor: _fila.length.toString(),
            icone: Icons.people_alt_outlined,
            cor: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _InfoCard(
            titulo: 'Atendidos Hoje',
            valor: _atendidosHoje.toString(),
            icone: Icons.check_circle_outline,
            cor: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildFilaDeEsperaList() {
    // Se a fila tem 0 ou 1 pessoa, não há "próximos" a serem mostrados na lista
    if (_fila.length <= 1) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            'Não há mais ninguém aguardando.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Começa do segundo item da lista, pois o primeiro já está no card de destaque
    final filaDeEspera = _fila.sublist(1);

    return ListView.builder(
      shrinkWrap: true, // Essencial para uma ListView dentro de outra rolagem
      physics:
          const NeverScrollableScrollPhysics(), // Desabilita a rolagem da lista interna
      itemCount: filaDeEspera.length,
      itemBuilder: (context, index) {
        final cliente = filaDeEspera[index];
        return Card(
          // ERRO 5 CORRIGIDO: Adicionada uma Key para otimizar o rebuild da lista.
          key: ValueKey(cliente.uid),
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(
                '#${index + 2}', // Posição real na fila
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              cliente.nome,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Entrou às: ${DateFormat('HH:mm').format(cliente.horaEntrada)}',
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.person_remove_outlined,
                color: Colors.redAccent,
              ),
              onPressed: () => _removerCliente(cliente.uid),
              tooltip: 'Remover da fila',
            ),
          ),
        );
      },
    );
  }
}

// Widget reutilizável para os cards de informação do dashboard
class _InfoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  const _InfoCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    // ERRO 6 CORRIGIDO: Verifica se a cor é MaterialColor antes de usar shades.
    final Color corValor =
        cor is MaterialColor ? (cor as MaterialColor).shade800 : cor;
    final Color corTitulo =
        cor is MaterialColor ? (cor as MaterialColor).shade700 : cor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 28),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: corValor,
            ),
          ),
          Text(titulo, style: TextStyle(color: corTitulo)),
        ],
      ),
    );
  }
}
