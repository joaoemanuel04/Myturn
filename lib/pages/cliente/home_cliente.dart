import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'fila_ativa.dart'; // Mantemos a navegação para a fila

// PASSO 1: CRIAR UM MODELO DE DADOS PARA O ESTABELECIMENTO
// Isso organiza o código, evita erros de digitação e melhora a performance.
class Estabelecimento {
  final String id;
  final String nome;
  final String categoria;
  final String cidade;
  final String estado;
  final bool filaAberta; // Novo campo para o status da fila
  final int contagemFila; // Novo campo para a contagem de pessoas

  Estabelecimento({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.cidade,
    required this.estado,
    this.filaAberta = false,
    this.contagemFila = 0,
  });
}

//--- TELA PRINCIPAL ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- VARIÁVEIS DE ESTADO ---
  bool _isLoading = true;
  String? estado;
  String? cidade;
  String _localizacaoDisplay = "Buscando sua localização...";

  String _categoriaSelecionada = "Restaurante";
  final TextEditingController _searchController = TextEditingController();

  // Lista principal que armazena os dados do Firebase
  List<Estabelecimento> _todosEstabelecimentos = [];
  // Lista que será exibida na tela (após filtros de busca e categoria)
  List<Estabelecimento> _estabelecimentosFiltrados = [];

  // Lista de categorias (mantida do seu código original)
  final List<String> categorias = [
    "Restaurante",
    "Bar",
    "Lanchonete",
    "Pizzaria",
    "Cafeteria",
    "Academia",
    "Salão de Beleza",
    "Supermercado",
    "Farmácia",
    "Clínica",
    "Pet Shop",
    "Outro",
  ];

  // --- CICLO DE VIDA E LÓGICA PRINCIPAL ---
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarEstabelecimentos);
    _iniciarBuscaDeLocalizacao();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filtrarEstabelecimentos);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _iniciarBuscaDeLocalizacao() async {
    // A lógica de permissão do seu código original é mantida aqui
    // (verificações de serviço, permissão, etc.)
    bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicoHabilitado) {
      if (mounted)
        setState(
          () =>
              _localizacaoDisplay = "GPS desativado. Ative para buscar locais.",
        );
      return;
    }
    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao != LocationPermission.whileInUse &&
          permissao != LocationPermission.always) {
        if (mounted)
          setState(
            () => _localizacaoDisplay = "Permissão de localização negada.",
          );
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final local = placemarks.first;
        setState(() {
          cidade = local.subAdministrativeArea;
          estado = local.administrativeArea;
          _localizacaoDisplay = "Exibindo locais em: $cidade, $estado";
        });
        _carregarEstabelecimentos();
      }
    } on TimeoutException {
      if (mounted)
        setState(
          () => _localizacaoDisplay = "Não foi possível obter a localização.",
        );
    } catch (e) {
      if (mounted)
        setState(() => _localizacaoDisplay = "Erro ao buscar localização.");
      print("Erro de geolocalização: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // PASSO 2: FUNÇÃO OTIMIZADA PARA CARREGAR DADOS
  Future<void> _carregarEstabelecimentos() async {
    if (cidade == null || estado == null) return;
    if (mounted) setState(() => _isLoading = true);

    final estabelecimentosRef = FirebaseDatabase.instance.ref(
      'estabelecimentos',
    );
    final filasRef = FirebaseDatabase.instance.ref('filas');

    final snapshot = await estabelecimentosRef.get();

    if (!snapshot.exists) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final List<Estabelecimento> estabelecimentosTemp = [];
    final List<Future> futures = [];

    final todos = Map<String, dynamic>.from(snapshot.value as Map);

    todos.forEach((id, dados) {
      final dadosMap = Map<String, dynamic>.from(dados);
      // Filtra pela localização ANTES de fazer outras buscas
      if (dadosMap['cidade'].toString().toLowerCase() ==
              cidade!.toLowerCase() &&
          dadosMap['estado'] == estado) {
        final future = Future(() async {
          // Busca o status da fila e a contagem de forma paralela
          final statusSnapshot =
              await estabelecimentosRef.child('$id/filaAberta').get();
          final contagemSnapshot = await filasRef.child('$id/clientes').get();

          return Estabelecimento(
            id: id,
            nome: dadosMap['name'] ?? 'Nome indisponível',
            categoria: dadosMap['categoria'] ?? 'Sem categoria',
            cidade: dadosMap['cidade'] ?? '',
            estado: dadosMap['estado'] ?? '',
            filaAberta: (statusSnapshot.value as bool?) ?? false,
            contagemFila:
                contagemSnapshot.exists ? contagemSnapshot.children.length : 0,
          );
        });

        futures.add(future.then((est) => estabelecimentosTemp.add(est)));
      }
    });

    // Espera todas as buscas paralelas terminarem
    await Future.wait(futures);

    if (mounted) {
      setState(() {
        _todosEstabelecimentos = estabelecimentosTemp;
        _isLoading = false;
      });
      _filtrarEstabelecimentos(); // Aplica o filtro inicial
    }
  }

  void _filtrarEstabelecimentos() {
    List<Estabelecimento> filtrados =
        _todosEstabelecimentos.where((est) {
          // Filtro por categoria
          final correspondeCategoria = est.categoria == _categoriaSelecionada;
          // Filtro por texto de busca (case-insensitive)
          final correspondeBusca = est.nome.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );
          return correspondeCategoria && correspondeBusca;
        }).toList();

    if (mounted) {
      setState(() {
        _estabelecimentosFiltrados = filtrados;
      });
    }
  }

  // --- CONSTRUÇÃO DA UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyTurn'),
        backgroundColor: const Color(0xFF2C7DA0), // Cor consistente
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF2C7DA0)),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              onTap: () => Navigator.pushNamed(context, '/perfil'),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text('Minhas Reservas'),
              onTap: () => Navigator.pushNamed(context, '/reservas'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // CABEÇALHO COM LOCALIZAÇÃO E BUSCA
          _buildHeader(),

          // FILTRO DE CATEGORIAS
          _buildCategoryFilter(),

          // CORPO PRINCIPAL
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _estabelecimentosFiltrados.isEmpty
                    ? const Center(
                      child: Text('Nenhum estabelecimento encontrado.'),
                    )
                    : RefreshIndicator(
                      onRefresh: _carregarEstabelecimentos,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // 2 colunas
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.9, // Proporção do card
                            ),
                        itemCount: _estabelecimentosFiltrados.length,
                        itemBuilder: (context, index) {
                          final est = _estabelecimentosFiltrados[index];
                          return EstabelecimentoCard(estabelecimento: est);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES PARA ORGANIZAR O CÓDIGO ---

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFE8F1F3), // Cor suave do splash
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _localizacaoDisplay,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Usando seu widget TextFieldInpute para consistência
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar pelo nome...',
              prefixIcon: const Icon(Icons.search, color: Colors.black45),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: categorias.length,
          itemBuilder: (context, index) {
            final cat = categorias[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(cat),
                selectedColor: const Color(0xFF2C7DA0),
                labelStyle: TextStyle(
                  color:
                      _categoriaSelecionada == cat
                          ? Colors.white
                          : Colors.black,
                ),
                selected: _categoriaSelecionada == cat,
                onSelected: (_) {
                  setState(() => _categoriaSelecionada = cat);
                  _filtrarEstabelecimentos();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// PASSO 3: CRIAR UM WIDGET PARA O CARD DO ESTABELECIMENTO
class EstabelecimentoCard extends StatelessWidget {
  final Estabelecimento estabelecimento;

  const EstabelecimentoCard({super.key, required this.estabelecimento});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navega para a tela de detalhes da fila
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => FilaAtivaScreen(
                  estabelecimentoId: estabelecimento.id,
                  nomeEstabelecimento: estabelecimento.nome,
                ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // NOME E CATEGORIA
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estabelecimento.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    estabelecimento.categoria,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),

              // STATUS DA FILA
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          estabelecimento.filaAberta
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      estabelecimento.filaAberta
                          ? 'FILA ABERTA'
                          : 'FILA FECHADA',
                      style: TextStyle(
                        color:
                            estabelecimento.filaAberta
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.people_alt_outlined,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${estabelecimento.contagemFila} na fila',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
