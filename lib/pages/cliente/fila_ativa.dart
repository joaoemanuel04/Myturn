// lib/pages/cliente/fila_ativa.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:myturn/Widget/snack_bar.dart';
import 'package:myturn/models/cliente_fila_model.dart';
import 'package:myturn/services/fila_service.dart';

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
  late final String uid;
  bool estaNaFila = false;
  int? posicaoNaFila;
  bool _isProcessing = false;
  StreamSubscription<DatabaseEvent>? _filaSubscription;
  String _currentEstabelecimentoName = "Carregando...";

  // Nova flag para controlar a tentativa de entrada automática na fila
  // Isso evita que 'entrarNaFila' seja chamado múltiplas vezes
  bool _hasAttemptedAutoJoin = false;

  @override
  void initState() {
    super.initState();
    // Garante que o UID do usuário logado nao seja nulo antes de usar.
    uid = FirebaseAuth.instance.currentUser!.uid;

    // Define o nome inicial a partir do argumento do widget.
    // Isso garante que o nome passado da rota seja exibido enquanto o carregamento real acontece.
    _currentEstabelecimentoName = widget.nomeEstabelecimento;

    // Inicia o carregamento do nome real do estabelecimento do Firebase.
    _carregarNomeEstabelecimento();

    // Inicia o listener para a posicao na fila. A lógica de auto-join será dentro do listener.
    _iniciarListenerDaFila();
  }

  @override
  void dispose() {
    _filaSubscription?.cancel();
    super.dispose();
  }

  // Metodo para carregar o nome do estabelecimento do Firebase.
  Future<void> _carregarNomeEstabelecimento() async {
    try {
      final snapshot =
          await FirebaseDatabase.instance
              .ref('estabelecimentos/${widget.estabelecimentoId}/name')
              .get();

      if (snapshot.exists && snapshot.value is String) {
        if (mounted) {
          setState(() {
            _currentEstabelecimentoName = snapshot.value as String;
          });
        }
      } else {
        // Se o snapshot nao existir ou nao for uma String, exibe um nome padrao.
        if (mounted) {
          setState(() {
            _currentEstabelecimentoName = "Estabelecimento Não Encontrado";
          });
        }
      }
    } catch (e) {
      // Em caso de erro na busca, exibe uma mensagem de erro.
      if (mounted) {
        setState(() {
          _currentEstabelecimentoName = "Erro ao Carregar Nome";
        });
      }
    }
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
          final data = Map<String, dynamic>.from(snapshot.value as Map);

          final List<ClienteFilaModel> filaCompleta =
              data.entries.map((entry) {
                return ClienteFilaModel.fromMap(
                  entry.key,
                  Map<String, dynamic>.from(entry.value),
                );
              }).toList();

          filaCompleta.sort((a, b) => a.horaEntrada.compareTo(b.horaEntrada));

          final index = filaCompleta.indexWhere(
            (cliente) => cliente.uid == uid,
          );

          if (index != -1) {
            // Usuário está na fila
            if (mounted) {
              setState(() {
                estaNaFila = true;
                posicaoNaFila = index + 1;
              });
            }
          } else {
            // Usuário NÃO está na fila
            if (mounted) {
              setState(() {
                estaNaFila = false;
                posicaoNaFila = null;
              });

              // Se o usuário não está na fila e ainda não tentamos a entrada automática,
              // chama 'entrarNaFila()'. Isso é útil quando o app é aberto via deep link
              // e o usuário deveria ser adicionado à fila automaticamente.
              if (!_hasAttemptedAutoJoin) {
                // Verifica se já tentou para evitar loop ou múltiplas chamadas
                _hasAttemptedAutoJoin = true; // Define a flag para true
                entrarNaFila(); // Chama a função para entrar na fila
              }
            }
          }
        } else {
          // Fila não existe ou está vazia
          if (mounted) {
            setState(() {
              estaNaFila = false;
              posicaoNaFila = null;
            });
            // Se a fila está vazia/não existe e ainda não tentamos o auto-join
            if (!_hasAttemptedAutoJoin) {
              _hasAttemptedAutoJoin = true;
              entrarNaFila();
            }
          }
        }
      },
      onError: (error) {
        // Lidar com erros no listener, talvez mostrando uma mensagem
      },
    );
  }

  Future<void> entrarNaFila() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final resultado = await FilaService.entrarNaFila(widget.estabelecimentoId);

    if (resultado == "success") {
      if (mounted) showSnackBar(context, "Você entrou na fila!");
    } else {
      if (mounted) showSnackBar(context, resultado);
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_currentEstabelecimentoName)),
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
