//Minhas Reservas
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MinhasReservasScreen extends StatefulWidget {
  @override
  _MinhasReservasScreenState createState() => _MinhasReservasScreenState();
}

class _MinhasReservasScreenState extends State<MinhasReservasScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> reservas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    carregarReservas();
  }

  // GARANTA QUE SUA FUNÇÃO SEJA EXATAMENTE IGUAL A ESTA

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
            _isLoading = false; // Importante desligar o loading aqui também
          });
        return;
      }

      final idsEstabelecimentos = Map<String, dynamic>.from(
        snapshotIds.value as Map,
      );

      final List<Future<Map<String, dynamic>?>> futures =
          idsEstabelecimentos.keys.map((idEstabelecimento) async {
            // Referências para as duas buscas
            final filaRef = FirebaseDatabase.instance.ref(
              'filas/$idEstabelecimento/clientes',
            );
            final estabelecimentoRef = FirebaseDatabase.instance.ref(
              'estabelecimentos/$idEstabelecimento',
            );

            // Executa as duas buscas em paralelo
            final results = await Future.wait([
              filaRef.get(),
              estabelecimentoRef.get(),
            ]);

            final snapshotFila = results[0];
            final snapshotEstabelecimento = results[1];

            // Se a fila OU o estabelecimento não forem encontrados, a reserva é inválida.
            if (!snapshotFila.exists || !snapshotEstabelecimento.exists) {
              return null;
            }

            // Garante que os dados são mapas antes de tentar usá-los
            if (snapshotFila.value is! Map ||
                snapshotEstabelecimento.value is! Map) {
              return null;
            }

            // --- Bloco para extrair o NOME ---
            final dadosEstabelecimento = Map<String, dynamic>.from(
              snapshotEstabelecimento.value as Map,
            );
            // Aqui garantimos que o nome seja extraído corretamente
            final nomeEstabelecimento =
                dadosEstabelecimento['name'] ?? 'Nome não disponível';

            // --- Bloco para calcular a POSIÇÃO ---
            final clientesNaFila = Map<String, dynamic>.from(
              snapshotFila.value as Map,
            );
            final listaDeEspera = clientesNaFila.keys.toList();
            final minhaPosicaoIndex = listaDeEspera.indexOf(uid);

            if (minhaPosicaoIndex == -1) return null;

            final minhaPosicao = minhaPosicaoIndex + 1;

            // --- Retorna o mapa COMPLETO ---
            return {
              'estabelecimentoId': idEstabelecimento,
              'nomeEstabelecimento':
                  nomeEstabelecimento, // A chave é adicionada AQUI
              'posicao': minhaPosicao,
              'total': clientesNaFila.length,
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
    // --- PASSO OPCIONAL, MAS RECOMENDADO: Diálogo de Confirmação ---
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
              onPressed: () {
                Navigator.of(context).pop(false); // Retorna 'false'
              },
            ),
            TextButton(
              child: Text('Sair', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true); // Retorna 'true'
              },
            ),
          ],
        );
      },
    );

    // Se o usuário não confirmou (pressionou 'Cancelar' ou fechou o diálogo), não faz nada.
    if (confirmar != true) {
      return;
    }

    // --- LÓGICA DE REMOÇÃO NO FIREBASE ---
    try {
      // Cria as duas referências para os locais que precisam ser deletados
      final filaRef = FirebaseDatabase.instance.ref(
        'filas/$idEstabelecimento/clientes/$uid',
      );
      final reservaUsuarioRef = FirebaseDatabase.instance.ref(
        'minhasReservasPorUsuario/$uid/$idEstabelecimento',
      );

      // Executa as duas remoções em paralelo para otimizar
      await Future.wait([filaRef.remove(), reservaUsuarioRef.remove()]);

      // Feedback de sucesso para o usuário
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Você saiu da fila com sucesso!')),
        );
        // Atualiza a lista de reservas na tela para remover o card
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
          reservas.isEmpty
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
                      // ADICIONE ESTE WIDGET 'trailing'
                      trailing: IconButton(
                        icon: Icon(Icons.exit_to_app, color: Colors.red[700]),
                        tooltip: 'Sair da fila',
                        // O onPressed vai chamar a função que criaremos no próximo passo
                        onPressed: () {
                          // Passamos o ID do estabelecimento para a função saber de qual fila sair
                          _sairDaFila(r['estabelecimentoId']);
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
