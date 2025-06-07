// lib/pages/estabelecimento/estabelecimento_home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
// ALTERAÇÃO: Import do model
import 'package:myturn/models/cliente_fila_model.dart';

// ALTERAÇÃO: Classe ClienteNaFila local foi REMOVIDA

class EstabelecimentoHomeScreen extends StatefulWidget {
  const EstabelecimentoHomeScreen({super.key});

  @override
  State<EstabelecimentoHomeScreen> createState() =>
      _EstabelecimentoHomeScreenState();
}

class _EstabelecimentoHomeScreenState extends State<EstabelecimentoHomeScreen> {
  final _auth = FirebaseAuth.instance;
  late final DatabaseReference _estabelecimentoRef;
  late final DatabaseReference _filaRef;
  late final DatabaseReference _metricasRef;

  StreamSubscription? _filaSubscription;
  StreamSubscription? _statusFilaSubscription;
  StreamSubscription? _metricasSubscription;

  // ALTERAÇÃO: A lista agora usa o ClienteFilaModel
  List<ClienteFilaModel> _fila = [];
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
    _filaSubscription?.cancel();
    _statusFilaSubscription?.cancel();
    _metricasSubscription?.cancel();
    super.dispose();
  }

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
    _escutarMetricas();
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
              _isLoading = false;
            });
          }
        });
  }

  void _escutarMudancasDaFila() {
    _filaSubscription = _filaRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        // ALTERAÇÃO: Usando o factory do ClienteFilaModel
        final novaFila =
            data.entries
                .map(
                  (e) => ClienteFilaModel.fromMap(
                    e.key,
                    Map<String, dynamic>.from(e.value),
                  ),
                )
                .toList();

        novaFila.sort((a, b) => a.horaEntrada.compareTo(b.horaEntrada));
        if (mounted) setState(() => _fila = novaFila);
      } else {
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
    try {
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

    final TransactionResult result = await _metricasRef
        .child('atendidosHoje')
        .runTransaction((Object? currentData) {
          int currentValue = (currentData as int?) ?? 0;
          return Transaction.success(currentValue + 1);
        });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Painel de Controle'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'sair') {
                await _auth.signOut();
                if (!mounted) return;
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

  Widget _buildProximoClienteCard() {
    final proximoCliente = _fila.isNotEmpty ? _fila.first : null;

    return Card(
      elevation: 4,
      color: Theme.of(context).primaryColor,
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
              proximoCliente?.nome ?? 'Ninguém na fila', // ALTERAÇÃO: Usa .nome
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (proximoCliente != null)
              Text(
                'Entrou às ${DateFormat('HH:mm').format(proximoCliente.horaEntrada)}', // ALTERAÇÃO: Usa .horaEntrada
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
              onPressed: proximoCliente != null ? _chamarProximoCliente : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaDeEsperaList() {
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

    final filaDeEspera = _fila.sublist(1);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filaDeEspera.length,
      itemBuilder: (context, index) {
        final cliente = filaDeEspera[index];
        return Card(
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
                '#${index + 2}',
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

  // Widgets _buildControleFilaCard e _buildMetricasDashboard não precisam de alteração
  Widget _buildControleFilaCard() {
    //... inalterado
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

  Widget _buildMetricasDashboard() {
    //... inalterado
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
}

class _InfoCard extends StatelessWidget {
  //... inalterado
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
