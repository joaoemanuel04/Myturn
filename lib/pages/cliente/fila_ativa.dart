//Fila Ativa 2
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FilaAtivaScreen extends StatefulWidget {
  final String estabelecimentoId;
  final String nomeEstabelecimento;

  FilaAtivaScreen({
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
    // 3. MUITO IMPORTANTE: Cancela o ouvinte quando a tela for fechada
    // para evitar vazamentos de memória e erros.
    _filaSubscription?.cancel();
    super.dispose();
  }

  // 4. A nova função que configura o ouvinte em tempo real
  void _iniciarListenerDaFila() {
    final filaRef = FirebaseDatabase.instance.ref(
      'filas/${widget.estabelecimentoId}/clientes',
    );

    // Cancela qualquer ouvinte anterior, por segurança
    _filaSubscription?.cancel();

    // .onValue.listen() é o que cria o ouvinte em tempo real
    _filaSubscription = filaRef.onValue.listen(
      (DatabaseEvent event) {
        final snapshot = event.snapshot;

        if (snapshot.exists && snapshot.value is Map) {
          final clientes = Map<String, dynamic>.from(snapshot.value as Map);
          final keys = clientes.keys.toList();
          final index = keys.indexWhere((key) => key == uid);

          // Se o usuário FOI encontrado na lista
          if (index != -1) {
            if (mounted) {
              setState(() {
                estaNaFila = true;
                posicaoNaFila = index + 1; // Posição atualizada em tempo real
              });
            }
          } else {
            // Se o usuário NÃO FOI encontrado na lista (ou saiu da fila)
            if (mounted) {
              setState(() {
                estaNaFila = false;
                posicaoNaFila = 0;
              });
            }
          }
        } else {
          // Se a fila está vazia ou não existe mais
          if (mounted) {
            setState(() {
              estaNaFila = false;
              posicaoNaFila = 0;
            });
          }
        }
      },
      onError: (error) {
        // Opcional: Lidar com possíveis erros de permissão de leitura
        print("Erro no listener da fila: $error");
      },
    );
  }

  Future<void> entrarNaFila() async {
    // Impede que o usuário clique no botão várias vezes
    if (_isProcessing) return;

    setState(() {
      _isProcessing =
          true; // Inicia o processamento, pode desabilitar o botão na UI
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print("Usuário não logado.");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: Usuário não está logado.")));
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // 1. BUSCA OS DADOS DO CLIENTE DE FORMA SEGURA
      // Ponto de atenção: No seu código você usou 'users/$uid'. Nos nossos exemplos anteriores,
      // usamos 'clientes/$uid'. Verifique qual é o caminho correto no seu banco de dados!
      // Usarei 'clientes/$uid' aqui, conforme o padrão anterior.
      final clienteRef = FirebaseDatabase.instance.ref('users/$uid');
      final clienteSnapshot = await clienteRef.get();

      if (!clienteSnapshot.exists) {
        print(
          "Erro Crítico: Perfil do cliente não encontrado no banco de dados.",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Seu perfil não foi encontrado. Não é possível entrar na fila.",
            ),
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      final dadosCliente = Map<String, dynamic>.from(
        clienteSnapshot.value as Map,
      );
      final nomeCliente = dadosCliente['name'] ?? 'Cliente sem nome';

      // 2. CRIA AS DUAS REFERÊNCIAS PARA A ESCRITA
      // Referência para a fila do estabelecimento
      final filaRef = FirebaseDatabase.instance.ref(
        'filas/${widget.estabelecimentoId}/clientes/$uid',
      );

      // Referência para o "índice" de reservas do usuário (a otimização)
      final reservaUsuarioRef = FirebaseDatabase.instance.ref(
        'minhasReservasPorUsuario/$uid/${widget.estabelecimentoId}',
      );

      // 3. EXECUTA AS DUAS ESCRITAS EM PARALELO PARA MAIOR EFICIÊNCIA
      await Future.wait([
        // Escreve os dados na fila do estabelecimento
        filaRef.set({
          'nome': nomeCliente,
          'horaEntrada': DateTime.now().toIso8601String(),
        }),
        // Escreve a "marcação" no perfil de reservas do usuário
        reservaUsuarioRef.set(true),
      ]);

      print("Usuário inserido na fila e no índice de reservas com sucesso!");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Você entrou na fila!")));

      //verificarSeEstaNaFila(); // Mantém a chamada para atualizar a UI
    } catch (e) {
      print("Ocorreu um erro ao entrar na fila: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ocorreu um erro. Tente novamente.")),
      );
    } finally {
      // Garante que o estado de processamento sempre termine
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.nomeEstabelecimento)),
      body: Center(
        child:
            estaNaFila
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Você já está na fila.'),
                    Text('Sua posição: $posicaoNaFila'),
                  ],
                )
                : ElevatedButton(
                  onPressed: entrarNaFila,
                  child: Text('Entrar na fila'),
                ),
      ),
    );
  }
}
