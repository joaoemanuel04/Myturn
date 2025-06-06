//home_filtro
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'fila_ativa.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? estado;
  String? cidade;
  String categoriaSelecionada = 'Restaurante';
  List<Map<String, dynamic>> estabelecimentos = [];

  final List<String> categorias = [
    "Restaurante",
    "Pizzaria",
    "Lanchonete",
    "Clínica",
    "Lavanderia",
    "Oficina Mecânica",
    "Banco",
    "Posto de Gasolina",
    "Loja de Eletrônicos",
    "Loja de Móveis",
    "Loja de Informática",
    "Loja de Brinquedos",
    "Loja de Esportes",
    "Loja de Cosméticos",
    "Bar",
    "Cafeteria",
    "Loja de Roupas",
    "Supermercado",
    "Farmácia",
    "Academia",
    "Salão de Beleza",
    "Pet Shop",
    "Outro",
  ];

  // ... dentro da sua classe _HomeScreenState
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    // É uma boa prática chamar a função após o primeiro frame ser renderizado
    // ou em resposta a uma ação do usuário (como um clique de botão).
    // Chamá-la aqui diretamente pode funcionar, mas pode ser mais robusto de outra forma.
    obterLocalizacao();
  }

  Future<void> obterLocalizacao() async {
    // O estado de loading já deve ser 'true' desde o início.
    // Se não for, adicione: if (mounted) setState(() => _isLoading = true);
    try {
      // --- 1. VERIFICAÇÃO DE SERVIÇO E PERMISSÃO (Lógica mantida) ---
      bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicoHabilitado) {
        print('Serviço de localização desabilitado.');
        // Você pode querer mostrar uma SnackBar ou um alerta para o usuário aqui
        return; // Retorna para não continuar
      }

      LocationPermission permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
        if (permissao != LocationPermission.whileInUse &&
            permissao != LocationPermission.always) {
          print('Permissão de localização negada.');
          return; // Retorna
        }
      }

      if (permissao == LocationPermission.deniedForever) {
        print('Permissão de localização negada permanentemente.');
        // Aqui você pode mostrar um alerta sugerindo abrir as configurações
        return; // Retorna
      }

      // --- 2. LÓGICA DE LOCALIZAÇÃO OTIMIZADA ---
      Position? posicao;

      // Tenta pegar a última localização conhecida do cache do sistema (rápido)
      posicao = await Geolocator.getLastKnownPosition();

      // Se não houver cache, busca uma nova localização com precisão média e time limit
      posicao ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Mais rápido que 'high'
        timeLimit: Duration(seconds: 10), // Limite de 10 segundos
      );

      print('Localização obtida: ${posicao.latitude}, ${posicao.longitude}');

      // --- 3. DECODIFICAÇÃO E CARREGAMENTO DOS DADOS ---
      List<Placemark> placemarks = await placemarkFromCoordinates(
        posicao.latitude,
        posicao.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark local = placemarks.first;

        // Atualiza o estado com a cidade e o estado obtidos
        if (mounted) {
          setState(() {
            // Usamos 'subAdministrativeArea' que geralmente corresponde à cidade
            cidade = local.subAdministrativeArea;
            // 'administrativeArea' geralmente corresponde ao estado
            estado = local.administrativeArea;
          });
        }

        print('Localização decodificada: $cidade, $estado');
        await carregarEstabelecimentos(); // Carrega os estabelecimentos para o local
      }
    } on TimeoutException {
      print(
        'Tempo para obter localização esgotado! Verifique sua conexão ou sinal de GPS.',
      );
      // Informar o usuário sobre o erro é uma boa prática
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível obter a localização.')),
        );
    } catch (e) {
      print('Ocorreu um erro inesperado ao obter a localização: $e');
    } finally {
      // --- 4. FINALIZAÇÃO ---
      // Este bloco SEMPRE será executado, garantindo que o loading seja desativado
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> carregarEstabelecimentos() async {
    if (cidade == null || estado == null) return;
    final snapshot =
        await FirebaseDatabase.instance.ref('estabelecimentos').get();
    if (snapshot.exists) {
      final todos = Map<String, dynamic>.from(snapshot.value as Map);
      final filtrados =
          todos.entries
              .where((e) {
                final dados = Map<String, dynamic>.from(e.value);
                return dados['categoria'] == categoriaSelecionada &&
                    dados['cidade'].toString().toLowerCase() ==
                        cidade!.toLowerCase() &&
                    dados['estado'] == estado;
              })
              .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
              .toList();

      setState(() => estabelecimentos = filtrados);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Estabelecimentos')),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text('Menu'),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              title: Text('Perfil'),
              onTap: () => Navigator.pushNamed(context, '/perfil'),
            ),
            ListTile(
              title: Text('Minhas Reservas'),
              onTap: () => Navigator.pushNamed(context, '/reservas'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final cat = categorias[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: categoriaSelecionada == cat,
                    onSelected: (_) {
                      setState(() => categoriaSelecionada = cat);
                      carregarEstabelecimentos();
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child:
                estabelecimentos.isEmpty
                    ? Center(child: Text('Nenhum estabelecimento encontrado.'))
                    : ListView.builder(
                      itemCount: estabelecimentos.length,
                      itemBuilder: (context, index) {
                        final est = estabelecimentos[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(est['nome'] ?? ''),
                            subtitle: Text(
                              '${est['cidade']} - ${est['estado']}',
                            ),
                            trailing: Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => FilaAtivaScreen(
                                        estabelecimentoId: est['id'],
                                        nomeEstabelecimento: est['name'],
                                      ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
