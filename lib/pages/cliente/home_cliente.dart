import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myturn/pages/cliente/fila_ativa.dart';

// 1. Modelo de Dados Limpo
class Estabelecimento {
  final String id;
  final String nome;
  final String categoria;
  final bool filaAberta;
  final int contagemFila;

  Estabelecimento({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.filaAberta,
    required this.contagemFila,
  });
}

// 2. Widget Principal da Nova Tela
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 3. Gerenciamento de Estado
  final _searchController = TextEditingController();
  final List<Estabelecimento> _listaCompleta = [];
  List<Estabelecimento> _listaFiltrada = [];
  String _categoriaSelecionada = "Restaurante";
  String _statusDisplay = "Buscando sua localização...";
  bool _isLoading = true;

  final List<String> _categorias = [
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filtrarLista);
    _iniciarCarregamento();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 4. Lógica de Carregamento Otimizada
  Future<void> _iniciarCarregamento() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _listaCompleta.clear();
        _listaFiltrada.clear();
      });
    }

    try {
      // Etapa A: Obter localização
      Position position = await _obterPosicaoAtual();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty || !mounted) return;

      final local = placemarks.first;
      final cidade = local.subAdministrativeArea;
      final estado = local.administrativeArea;

      if (cidade == null || estado == null) {
        setState(
          () => _statusDisplay = "Não foi possível determinar sua cidade.",
        );
        return;
      }

      setState(() => _statusDisplay = "Exibindo locais em: $cidade, $estado");

      // Etapa B: Carregar estabelecimentos da cidade de forma progressiva
      await _carregarEstabelecimentos(cidade, estado);
    } catch (e) {
      if (mounted) setState(() => _statusDisplay = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Position> _obterPosicaoAtual() async {
    bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicoHabilitado) throw 'GPS desativado. Por favor, ative-o.';

    LocationPermission permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
      if (permissao == LocationPermission.denied) {
        throw 'Permissão de localização negada.';
      }
    }
    if (permissao == LocationPermission.deniedForever) {
      throw 'Permissão de localização negada permanentemente.';
    }
    return await Geolocator.getCurrentPosition(
      timeLimit: const Duration(seconds: 10),
    );
  }

  Future<void> _carregarEstabelecimentos(String cidade, String estado) async {
    final ref = FirebaseDatabase.instance.ref('estabelecimentos');
    // Otimização: A query busca apenas pela cidade no servidor. O estado é filtrado no cliente.
    final query = ref.orderByChild('cidade').equalTo(cidade);
    final snapshot = await query.get();

    if (!snapshot.exists || !mounted) return;

    final todos = Map<String, dynamic>.from(snapshot.value as Map);

    for (final entry in todos.entries) {
      if (!mounted) break;
      final id = entry.key;
      final dados = Map<String, dynamic>.from(entry.value);

      // Filtro complementar pelo estado
      if (dados['estado'] == estado) {
        try {
          // Busca os detalhes da fila APENAS para este estabelecimento
          final contagemSnapshot =
              await FirebaseDatabase.instance.ref('filas/$id/clientes').get();

          final est = Estabelecimento(
            id: id,
            nome: dados['name'] ?? 'Nome indisponível',
            categoria: dados['categoria'] ?? 'Sem Categoria',
            // O status da fila já vem no próprio objeto do estabelecimento, mais otimizado
            filaAberta: (dados['filaAberta'] as bool?) ?? false,
            contagemFila:
                contagemSnapshot.exists ? contagemSnapshot.children.length : 0,
          );

          _listaCompleta.add(est);
          _filtrarLista(); // Atualiza a UI a cada item carregado
        } catch (e) {
          // Ignora erro em um único estabelecimento para não parar todo o processo
        }
      }
    }
  }

  void _filtrarLista() {
    final termoBusca = _searchController.text.toLowerCase();
    setState(() {
      _listaFiltrada =
          _listaCompleta.where((est) {
            final correspondeCategoria = est.categoria == _categoriaSelecionada;
            final correspondeBusca = est.nome.toLowerCase().contains(
              termoBusca,
            );
            return correspondeCategoria && correspondeBusca;
          }).toList();
    });
  }

  // 5. Build da UI Limpa e Componentizada
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(title: const Text('MyTurn'), centerTitle: true),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _iniciarCarregamento,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildCategoryFilter()),
            _buildBodyContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _statusDisplay,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar pelo nome do local...',
              prefixIcon: const Icon(Icons.search, color: Colors.black45),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categorias.length,
        itemBuilder: (context, index) {
          final cat = _categorias[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(cat),
              selected: _categoriaSelecionada == cat,
              onSelected: (_) {
                setState(() => _categoriaSelecionada = cat);
                _filtrarLista();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_listaFiltrada.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum estabelecimento encontrado',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final est = _listaFiltrada[index];
          return EstabelecimentoCard(estabelecimento: est);
        }, childCount: _listaFiltrada.length),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Meu Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/perfil');
            },
          ),
          ListTile(
            leading: const Icon(Icons.list_alt_outlined),
            title: const Text('Minhas Reservas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reservas');
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.red.shade700),
            title: Text('Sair', style: TextStyle(color: Colors.red.shade700)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/splash', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class EstabelecimentoCard extends StatelessWidget {
  final Estabelecimento estabelecimento;
  const EstabelecimentoCard({super.key, required this.estabelecimento});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => FilaAtivaScreen(
                      estabelecimentoId: estabelecimento.id,
                      nomeEstabelecimento: estabelecimento.nome,
                    ),
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.storefront,
                  color: Theme.of(context).primaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estabelecimento.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estabelecimento.categoria,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          estabelecimento.filaAberta
                              ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      estabelecimento.filaAberta ? 'ABERTA' : 'FECHADA',
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
                      const SizedBox(width: 6),
                      Text(
                        '${estabelecimento.contagemFila}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
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
