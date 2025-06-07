// lib/pages/cliente/reservas.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// ALTERAÇÃO: Importar o model de cliente na fila para podermos ordenar pela hora de entrada
import 'package:myturn/models/cliente_fila_model.dart';

class MinhasReservasScreen extends StatefulWidget {
  @override
  _MinhasReservasScreenState createState() => _MinhasReservasScreenState();
}

class _MinhasReservasScreenState extends State<MinhasReservasScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  // Sugestão: Podemos criar um model para a reserva também, mas por enquanto vamos manter o Map
  List<Map<String, dynamic>> reservas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    carregarReservas();
  }

  Future<void> carregarReservas() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final minhasReservasRef = FirebaseDatabase.instance.ref(
        'minhasReservasPorUsuario/$uid',
      );
      final snapshotIds = await minhasReservasRef.get();

      if (!snapshotIds.exists) {
        if (mounted)
          setState(() {
            reservas = [];
            _isLoading = false;
          });
        return;
      }

      final idsEstabelecimentos = Map<String, dynamic>.from(
        snapshotIds.value as Map,
      );

      final List<Future<Map<String, dynamic>?>> futures =
          idsEstabelecimentos.keys.map((idEstabelecimento) async {
            final filaRef = FirebaseDatabase.instance.ref(
              'filas/$idEstabelecimento/clientes',
            );
            final estabelecimentoRef = FirebaseDatabase.instance.ref(
              'estabelecimentos/$idEstabelecimento',
            );

            final results = await Future.wait([
              filaRef.get(),
              estabelecimentoRef.get(),
            ]);
            final snapshotFila = results[0];
            final snapshotEstabelecimento = results[1];

            if (!snapshotFila.exists || !snapshotEstabelecimento.exists)
              return null;
            if (snapshotFila.value is! Map ||
                snapshotEstabelecimento.value is! Map)
              return null;

            final dadosEstabelecimento = Map<String, dynamic>.from(
              snapshotEstabelecimento.value as Map,
            );
            final nomeEstabelecimento =
                dadosEstabelecimento['name'] ?? 'Nome não disponível';

            // --- INÍCIO DA CORREÇÃO NO CÁLCULO DA POSIÇÃO ---
            final clientesData = Map<String, dynamic>.from(
              snapshotFila.value as Map,
            );

            // 1. Converte o mapa de clientes para uma lista de objetos ClienteFilaModel
            final List<ClienteFilaModel> filaOrdenada =
                clientesData.entries.map((entry) {
                  return ClienteFilaModel.fromMap(
                    entry.key,
                    Map<String, dynamic>.from(entry.value),
                  );
                }).toList();

            // 2. Ordena a lista pela hora de entrada
            filaOrdenada.sort((a, b) => a.horaEntrada.compareTo(b.horaEntrada));

            // 3. Encontra o índice do usuário na lista JÁ ORDENADA
            final minhaPosicaoIndex = filaOrdenada.indexWhere(
              (cliente) => cliente.uid == uid,
            );
            // --- FIM DA CORREÇÃO ---

            if (minhaPosicaoIndex == -1) return null;

            final minhaPosicao = minhaPosicaoIndex + 1;

            return {
              'estabelecimentoId': idEstabelecimento,
              'nomeEstabelecimento': nomeEstabelecimento,
              'posicao': minhaPosicao,
              'total':
                  filaOrdenada.length, // Usamos o tamanho da lista ordenada
              'tempoEstimado': (minhaPosicao * 5),
            };
          }).toList();

      final resultados = await Future.wait(futures);
      final minhasReservasEncontradas =
          resultados
              .where((r) => r != null)
              .cast<Map<String, dynamic>>()
              .toList();

      if (mounted) {
        setState(() {
          reservas = minhasReservasEncontradas;
        });
      }
    } catch (e) {
      print("Erro ao carregar reservas: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sairDaFila(String idEstabelecimento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sair da Fila'),
          content: Text(
            'Tem certeza que deseja sair da fila deste estabelecimento?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Sair', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      final filaRef = FirebaseDatabase.instance.ref(
        'filas/$idEstabelecimento/clientes/$uid',
      );
      final reservaUsuarioRef = FirebaseDatabase.instance.ref(
        'minhasReservasPorUsuario/$uid/$idEstabelecimento',
      );

      await Future.wait([filaRef.remove(), reservaUsuarioRef.remove()]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Você saiu da fila com sucesso!')),
        );
        carregarReservas();
      }
    } catch (e) {
      print("Erro ao sair da fila: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocorreu um erro ao tentar sair da fila.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Minhas Reservas')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : reservas.isEmpty
              ? Center(child: Text('Nenhuma reserva ativa.'))
              : ListView.builder(
                itemCount: reservas.length,
                itemBuilder: (context, index) {
                  final r = reservas[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(
                        r['nomeEstabelecimento'] ??
                            'Estabelecimento não encontrado',
                      ),
                      subtitle: Text(
                        'Posição: ${r['posicao']} de ${r['total']}\nTempo estimado: ${r['tempoEstimado']} minutos',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.exit_to_app, color: Colors.red[700]),
                        tooltip: 'Sair da fila',
                        onPressed: () => _sairDaFila(r['estabelecimentoId']),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
