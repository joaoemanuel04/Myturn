import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Seus imports personalizados (verifique os caminhos)
import 'package:myturn/Estabelecimento_Login_Sing_Up/Services/estabelecimento_auth.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/estabelecimento_success.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/estabelecimento_login.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/map_picker_screen.dart';
import 'package:myturn/Widget/button.dart';
import 'package:myturn/Widget/snack_bar.dart';
import 'package:myturn/Widget/text_field.dart';
import 'package:myturn/esqueceu_senha/esqueceu_senha.dart';

//############################################################################
//###                                                                      ###
//###                  CÓDIGO COMPLETO PARA A TELA DE CADASTRO               ###
//###                                                                      ###
//############################################################################

//--- WIDGET DA TELA PRINCIPAL ---

class EstabelecimentoSignUpScreen extends StatefulWidget {
  const EstabelecimentoSignUpScreen({super.key});

  @override
  State<EstabelecimentoSignUpScreen> createState() =>
      _EstabelecimentoSignUpScreenState();
}

class _EstabelecimentoSignUpScreenState
    extends State<EstabelecimentoSignUpScreen> {
  // --- Controllers Principais ---
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController categoriaController = TextEditingController();
  final TextEditingController cnpjController = TextEditingController();
  final TextEditingController celularController = TextEditingController();
  final TextEditingController estadoController = TextEditingController();
  final TextEditingController cidadeController = TextEditingController();

  // Usando o modelo de dados para simplificar o gerenciamento de estado
  final Map<String, HorarioDia> horarios = {
    'domingo': HorarioDia(),
    'segunda': HorarioDia(),
    'terca': HorarioDia(),
    'quarta': HorarioDia(),
    'quinta': HorarioDia(),
    'sexta': HorarioDia(),
    'sabado': HorarioDia(),
  };

  final List<String> categorias = [
    "Restaurante",
    "Pizzaria",
    "Lanchonete",
    "Clinica",
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

  bool isLoading = false;

  LatLng? _selectedLocation;

  // IMPORTANTE: Adicionar o método dispose para liberar os recursos
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    categoriaController.dispose();
    cnpjController.dispose();
    celularController.dispose();
    estadoController.dispose();
    cidadeController.dispose();

    // Dispara o dispose de cada controller dentro do nosso modelo
    for (var horario in horarios.values) {
      horario.dispose();
    }
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    // Abre a tela do mapa e aguarda o usuário selecionar uma localização
    final LatLng? pickedLocation = await Navigator.of(context).push(
      MaterialPageRoute(
        // VERIFIQUE SE O NOME AQUI ESTÁ CORRETO:
        builder: (context) => const MapPickerScreen(),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
      });
      if (mounted) {
        showSnackBar(context, 'Localização selecionada com sucesso!');
      }
    }
  }

  void signUpEstabelecimento() async {
    // Adicione suas validações aqui antes de prosseguir
    if (passwordController.text != confirmPasswordController.text) {
      showSnackBar(context, "As senhas não coincidem.");
      return;
    }

    setState(() => isLoading = true);

    final horariosData = horarios.map((dia, horario) {
      return MapEntry(dia, {
        'inicio': horario.inicioController.text.trim(),
        'fim': horario.fimController.text.trim(),
        'fechado': horario.isFechado,
        'vinteQuatroHoras': horario.is24h,
      });
    });

    if (_selectedLocation == null) {
      showSnackBar(context, "Por favor, selecione a localização no mapa.");
      // Se você tiver uma variável de loading, é bom pará-la aqui também
      // setState(() => isLoading = false);
      return;
    }

    String res = await EstabelecimentoAuthService().signUpEstabelecimento(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      name: nameController.text.trim(),
      categoria: categoriaController.text.trim(),
      cnpj: cnpjController.text.trim(),
      celular: celularController.text.trim(),
      estado: estadoController.text.trim(),
      cidade: cidadeController.text.trim(),
      horarios: horariosData,
      // ALTERAÇÃO: Adicionando os 2 campos restantes
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
    );

    if (mounted) {
      // Boa prática: verificar se o widget ainda está na tela
      setState(() => isLoading = false);

      if (res == "success") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const EstabelecimentoSuccessScreen(),
          ),
        );
      } else {
        showSnackBar(context, res);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            // Alterado de SingleChildScrollView(child: Column(...)) para ListView()
            // crossAxisAlignment: CrossAxisAlignment.center, // O ListView não tem essa propriedade, o alinhamento é feito nos próprios filhos.
            children: [
              SizedBox(
                width: double.infinity,
                height: height / 4,
                child: Image.asset("assets/images/estabelecimento.png"),
              ),
              const Text(
                "Cadastro",
                textAlign:
                    TextAlign.center, // Adicionado para centralizar o texto
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              TextFieldInpute(
                textEditingController: nameController,
                hintText: "Nome do estabelecimento *",
                icon: Icons.store,
              ),
              CategoriaAutocompleteInpute(
                controller: categoriaController,
                categorias: categorias,
                icon: Icons.category,
                hintText: "Categoria *",
              ),
              TextFieldInpute(
                textEditingController: cnpjController,
                hintText: "CNPJ *",
                icon: Icons.badge,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CnpjInputFormatter(),
                ],
              ),
              TextFieldInpute(
                textEditingController: celularController,
                hintText: "Celular *",
                icon: Icons.phone_android,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TelefoneInputFormatter(),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Endereço e Localização",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextFieldInpute(
                textEditingController: estadoController,
                hintText: "Estado *",
                icon: Icons.location_on,
              ),
              TextFieldInpute(
                textEditingController: cidadeController,
                hintText: "Cidade *",
                icon: Icons.location_city,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: Icon(
                  _selectedLocation == null
                      ? Icons.map_outlined
                      : Icons.check_circle,
                  color:
                      _selectedLocation == null
                          ? Theme.of(context).primaryColor
                          : Colors.green,
                ),
                label: Text(
                  _selectedLocation == null
                      ? "Selecionar Localização Exata no Mapa *"
                      : "Localização Selecionada!",
                ),
                onPressed: _openMapPicker,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Horário de funcionamento:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),

              // Mapeando para o novo widget de horário isolado
              ...horarios.entries.map((entry) {
                return HorarioDiaInputWidget(
                  dia: entry.key,
                  horario: entry.value,
                );
              }).toList(),
              TextFieldInpute(
                textEditingController: emailController,
                hintText: "E-mail *",
                icon: Icons.email,
              ),
              TextFieldInpute(
                textEditingController: passwordController,
                hintText: "Senha *",
                icon: Icons.lock,
                ispass: true, // Assumindo que seu widget tem essa propriedade
              ),
              TextFieldInpute(
                textEditingController: confirmPasswordController,
                hintText: "Confirmação de Senha *",
                icon: Icons.lock_outline,
                ispass: true, // Assumindo que seu widget tem essa propriedade
              ),
              const ForgotPassword(),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "* Campos obrigatórios",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              MyButton(
                onTab: signUpEstabelecimento,
                text: isLoading ? "Carregando..." : "Cadastrar",
              ),
              SizedBox(height: height / 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Já tem uma conta?",
                    style: TextStyle(fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const EstabelecimentoLoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      " Entrar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

//--- WIDGET PARA O CAMPO DE CATEGORIA (AUTOCOMPLETE) ---

class CategoriaAutocompleteInpute extends StatefulWidget {
  final TextEditingController controller;
  final List<String> categorias;
  final IconData icon;
  final String hintText;

  const CategoriaAutocompleteInpute({
    super.key,
    required this.controller,
    required this.categorias,
    required this.icon,
    required this.hintText,
  });

  @override
  State<CategoriaAutocompleteInpute> createState() =>
      _CategoriaAutocompleteInputeState();
}

class _CategoriaAutocompleteInputeState
    extends State<CategoriaAutocompleteInpute> {
  List<String> filteredCategorias = [];
  bool showDropdown = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Esconde o dropdown quando o campo perde o foco
    if (!_focusNode.hasFocus) {
      setState(() {
        showDropdown = false;
      });
    }
  }

  void _onChanged() {
    final text = widget.controller.text.toLowerCase();
    if (text.isEmpty) {
      if (showDropdown) {
        setState(() {
          showDropdown = false;
          filteredCategorias = [];
        });
      }
      return;
    }

    final newFilteredList =
        widget.categorias
            .where((cat) => cat.toLowerCase().contains(text))
            .toList();

    setState(() {
      filteredCategorias = newFilteredList;
      showDropdown = filteredCategorias.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lembre-se de adicionar a propriedade `focusNode` ao seu widget `TextFieldInpute`
        TextFieldInpute(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          hintText: widget.hintText,
          icon: widget.icon,
        ),
        if (showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            // Usar ListView.builder é mais eficiente para listas
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: filteredCategorias.length,
              itemBuilder: (context, index) {
                final cat = filteredCategorias[index];
                return ListTile(
                  title: Text(cat),
                  onTap: () {
                    widget.controller.text = cat;
                    _focusNode.unfocus();
                    setState(() {
                      showDropdown = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

//--- MODELO DE DADOS E WIDGET PARA O HORÁRIO DE CADA DIA ---

// Um modelo para organizar os dados de cada dia
class HorarioDia {
  final TextEditingController inicioController = TextEditingController();
  final TextEditingController fimController = TextEditingController();
  bool isFechado = false;
  bool is24h = false;

  void dispose() {
    inicioController.dispose();
    fimController.dispose();
  }
}

// Widget Stateful isolado para a lógica de um dia da semana
class HorarioDiaInputWidget extends StatefulWidget {
  final String dia;
  final HorarioDia horario;

  const HorarioDiaInputWidget({
    super.key,
    required this.dia,
    required this.horario,
  });

  @override
  State<HorarioDiaInputWidget> createState() => _HorarioDiaInputWidgetState();
}

class _HorarioDiaInputWidgetState extends State<HorarioDiaInputWidget> {
  // O estado agora é controlado dentro deste widget
  void _onFechadoChanged(bool? value) {
    setState(() {
      widget.horario.isFechado = value ?? false;
      if (widget.horario.isFechado) {
        widget.horario.is24h = false;
        widget.horario.inicioController.clear();
        widget.horario.fimController.clear();
      }
    });
  }

  void _on24hChanged(bool? value) {
    setState(() {
      widget.horario.is24h = value ?? false;
      if (widget.horario.is24h) {
        widget.horario.isFechado = false;
        widget.horario.inicioController.text = '00:00';
        widget.horario.fimController.text = '23:59';
      } else {
        widget.horario.inicioController.clear();
        widget.horario.fimController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String diaCapitalizado =
        "${widget.dia[0].toUpperCase()}${widget.dia.substring(1)}";
    final bool isEnabled = !widget.horario.isFechado && !widget.horario.is24h;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$diaCapitalizado:",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Row(
            children: [
              Checkbox(
                value: widget.horario.isFechado,
                onChanged: _onFechadoChanged,
              ),
              const Text("Fechado"),
              const SizedBox(width: 10),
              Checkbox(value: widget.horario.is24h, onChanged: _on24hChanged),
              const Text("24h"),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFieldInpute(
                  textEditingController: widget.horario.inicioController,
                  hintText: "Início",
                  icon: Icons.access_time,
                  enabled: isEnabled,
                  inputFormatters: [HoraInputFormatter()],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFieldInpute(
                  textEditingController: widget.horario.fimController,
                  hintText: "Fim",
                  icon: Icons.access_time,
                  enabled: isEnabled,
                  inputFormatters: [HoraInputFormatter()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
