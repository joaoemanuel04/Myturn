import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'fila_ativa.dart';
import 'package:myturn/models/estabelecimento_model.dart';
// O scanner ainda não foi implementado, então podemos deixar o import comentado ou removê-lo por enquanto.
// import 'package:myturn/pages/cliente/qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? estado;
  String? cidade;
  String _localizacaoDisplay = "Buscando sua localização...";

  String _categoriaSelecionada = "Restaurante";
  final TextEditingController _searchController = TextEditingController();

  List<EstabelecimentoModel> _todosEstabelecimentos = [];
  List<EstabelecimentoModel> _estabelecimentosFiltrados = [];

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
        await _carregarEstabelecimentos();
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

  // ALTERAÇÃO: A função agora carrega apenas os dados estáticos dos estabelecimentos.
  // As informações da fila (status e contagem) serão responsabilidade de cada card individualmente.
  Future<void> _carregarEstabelecimentos() async {
    if (cidade == null || estado == null) return;
    if (mounted) setState(() => _isLoading = true);

    final estabelecimentosRef = FirebaseDatabase.instance.ref(
      'estabelecimentos',
    );
    final snapshot = await estabelecimentosRef.get();

    if (!snapshot.exists) {
      if (mounted) {
        setState(() {
          _todosEstabelecimentos = [];
          _isLoading = false;
        });
        _filtrarEstabelecimentos();
      }
      return;
    }

    final List<EstabelecimentoModel> estabelecimentosTemp = [];
    final todos = Map<String, dynamic>.from(snapshot.value as Map);

    todos.forEach((id, dados) {
      final dadosMap = Map<String, dynamic>.from(dados);
      if (dadosMap['cidade']?.toString().toLowerCase() ==
              cidade!.toLowerCase() &&
          dadosMap['estado'] == estado) {
        // Apenas criamos o modelo com os dados que já temos.
        // O card cuidará do resto.
        estabelecimentosTemp.add(
          EstabelecimentoModel.fromMap(dadosMap..['uid'] = id),
        );
      }
    });

    if (mounted) {
      setState(() {
        _todosEstabelecimentos = estabelecimentosTemp;
      });
      _filtrarEstabelecimentos();
    }
  }

  void _filtrarEstabelecimentos() {
    List<EstabelecimentoModel> filtrados =
        _todosEstabelecimentos.where((est) {
          final correspondeCategoria = est.categoria == _categoriaSelecionada;
          final correspondeBusca = est.name.toLowerCase().contains(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyTurn'),
        backgroundColor: const Color(0xFF2C7DA0),
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
      // O botão do scanner pode ser adicionado aqui depois.
      // floatingActionButton: FloatingActionButton(...)
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryFilter(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _estabelecimentosFiltrados.isEmpty
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Nenhum estabelecimento encontrado para a categoria "$_categoriaSelecionada" em sua cidade.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _carregarEstabelecimentos,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                        itemCount: _estabelecimentosFiltrados.length,
                        itemBuilder: (context, index) {
                          final est = _estabelecimentosFiltrados[index];
                          return EstabelecimentoCard(
                            key: ValueKey(est.uid),
                            estabelecimento: est,
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFE8F1F3),
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

// =========================================================================
// ALTERAÇÃO PRINCIPAL: O CARD AGORA É STATEFUL E ESCUTA MUDANÇAS EM TEMPO REAL
// =========================================================================
class EstabelecimentoCard extends StatefulWidget {
  final EstabelecimentoModel estabelecimento;

  const EstabelecimentoCard({super.key, required this.estabelecimento});

  @override
  State<EstabelecimentoCard> createState() => _EstabelecimentoCardState();
}

class _EstabelecimentoCardState extends State<EstabelecimentoCard> {
  // Variáveis de estado para os dados em tempo real
  late bool _filaAberta;
  late int _contagemFila;

  // Controladores dos listeners para poder cancelá-los depois
  StreamSubscription? _statusSubscription;
  StreamSubscription? _contagemSubscription;

  @override
  void initState() {
    super.initState();
    // 1. Inicializa o estado com os dados recebidos para exibição imediata
    _filaAberta = widget.estabelecimento.filaAberta;
    _contagemFila = 0; // Começa com 0 até o listener trazer o valor real

    // 2. Inicia os listeners para os dados em tempo real
    final dbRef = FirebaseDatabase.instance.ref();

    // Listener para o status da fila (aberta/fechada)
    _statusSubscription = dbRef
        .child('estabelecimentos/${widget.estabelecimento.uid}/filaAberta')
        .onValue
        .listen((event) {
          if (mounted) {
            // Garante que o widget ainda está na tela
            setState(() {
              _filaAberta = (event.snapshot.value as bool?) ?? false;
            });
          }
        });

    // Listener para a contagem de pessoas na fila
    _contagemSubscription = dbRef
        .child('filas/${widget.estabelecimento.uid}/clientes')
        .onValue
        .listen((event) {
          if (mounted) {
            setState(() {
              _contagemFila = event.snapshot.children.length;
            });
          }
        });
  }

  @override
  void dispose() {
    // 3. Cancela os listeners quando o widget é removido da tela para evitar erros
    _statusSubscription?.cancel();
    _contagemSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => FilaAtivaScreen(
                  estabelecimentoId: widget.estabelecimento.uid,
                  nomeEstabelecimento: widget.estabelecimento.name,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.estabelecimento.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.estabelecimento.categoria,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4. A UI agora usa as variáveis de ESTADO (_filaAberta, _contagemFila)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _filaAberta
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _filaAberta ? 'FILA ABERTA' : 'FILA FECHADA',
                      style: TextStyle(
                        color:
                            _filaAberta
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
                        '$_contagemFila na fila',
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
