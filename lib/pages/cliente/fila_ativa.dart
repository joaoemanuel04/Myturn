// lib/pages/cliente/fila_ativa.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:myturn/Widget/snack_bar.dart';
// ALTERAÇÃO: Importaremos o model de cliente na fila que já criamos
import 'package:myturn/models/cliente_fila_model.dart';

class FilaAtivaScreen extends StatefulWidget {
  final String estabelecimentoId;
  final String nomeEstabelecimento;

  FilaAtivaScreen({
    super.key,
    required this.estabelecimentoId,
    required this.nomeEstabelecimento,
  });

  @override
  _FilaAtivaScreenState createState() => _FilaAtivaScreenState();
}

class _FilaAtivaScreenState extends State<FilaAtivaScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  bool estaNaFila = false;
  int? posicaoNaFila;
  bool _isProcessing = false;
  StreamSubscription<DatabaseEvent>? _filaSubscription;

  @override
  void initState() {
    super.initState();
    _iniciarListenerDaFila();
  }

  @override
  void dispose() {
    _filaSubscription?.cancel();
    super.dispose();
  }

  void _iniciarListenerDaFila() {
    final filaRef = FirebaseDatabase.instance.ref(
      'filas/${widget.estabelecimentoId}/clientes',
    );

    _filaSubscription?.cancel();

    _filaSubscription = filaRef.onValue.listen(
      (DatabaseEvent event) {
        final snapshot = event.snapshot;

        if (snapshot.exists && snapshot.value is Map) {
          // --- INÍCIO DA CORREÇÃO ---
          final data = Map<String, dynamic>.from(snapshot.value as Map);

          // 1. Converte todos os clientes do mapa para uma lista de objetos ClienteFilaModel
          final List<ClienteFilaModel> filaCompleta =
              data.entries.map((entry) {
                return ClienteFilaModel.fromMap(
                  entry.key,
                  Map<String, dynamic>.from(entry.value),
                );
              }).toList();

          // 2. Ordena a lista pela hora de entrada (do mais antigo para o mais novo)
          filaCompleta.sort((a, b) => a.horaEntrada.compareTo(b.horaEntrada));

          // 3. Encontra a posição (index) do usuário atual NA LISTA ORDENADA
          final index = filaCompleta.indexWhere(
            (cliente) => cliente.uid == uid,
          );
          // --- FIM DA CORREÇÃO ---

          if (index != -1) {
            if (mounted) {
              setState(() {
                estaNaFila = true;
                // A posição correta é o index + 1
                posicaoNaFila = index + 1;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                estaNaFila = false;
                posicaoNaFila = null;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              estaNaFila = false;
              posicaoNaFila = null;
            });
          }
        }
      },
      onError: (error) {
        print("Erro no listener da fila: $error");
      },
    );
  }

  Future<void> entrarNaFila() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) showSnackBar(context, "Erro: Usuário não está logado.");
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final clienteRef = FirebaseDatabase.instance.ref('users/$uid');
      final clienteSnapshot = await clienteRef.get();

      if (!clienteSnapshot.exists) {
        if (mounted)
          showSnackBar(
            context,
            "Seu perfil não foi encontrado. Não é possível entrar na fila.",
          );
        setState(() => _isProcessing = false);
        return;
      }

      final dadosCliente = Map<String, dynamic>.from(
        clienteSnapshot.value as Map,
      );
      final nomeCliente = dadosCliente['name'] ?? 'Cliente sem nome';

      final filaRef = FirebaseDatabase.instance.ref(
        'filas/${widget.estabelecimentoId}/clientes/$uid',
      );
      final reservaUsuarioRef = FirebaseDatabase.instance.ref(
        'minhasReservasPorUsuario/$uid/${widget.estabelecimentoId}',
      );

      // Usando o model ClienteFilaModel para criar os dados
      final clienteParaFila = ClienteFilaModel(
        uid: uid,
        nome: nomeCliente,
        horaEntrada: DateTime.now(),
      );

      await Future.wait([
        filaRef.set(clienteParaFila.toMap()), // Salva usando toMap()
        reservaUsuarioRef.set(true),
      ]);

      if (mounted) showSnackBar(context, "Você entrou na fila!");
    } catch (e) {
      if (mounted) showSnackBar(context, "Ocorreu um erro. Tente novamente.");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // O método build() continua o mesmo
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.nomeEstabelecimento)),
      body: Center(
        child:
            _isProcessing
                ? CircularProgressIndicator()
                : estaNaFila
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Você está na fila!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Sua posição:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '#$posicaoNaFila',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
                : ElevatedButton(
                  onPressed: entrarNaFila,
                  child: const Text('Entrar na fila'),
                ),
      ),
    );
  }
}
