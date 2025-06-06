import 'package:flutter/material.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/Services/estabelecimento_auth.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/estabelecimento_success.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/estabelecimento_login.dart';
import 'package:myturn/Widget/button.dart';
import 'package:myturn/Widget/snack_bar.dart';
import 'package:myturn/Widget/text_field.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:br_validators/br_validators.dart';
import 'package:flutter/services.dart';

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

  void _onChanged() {
    final text = widget.controller.text.toLowerCase();
    setState(() {
      filteredCategorias =
          widget.categorias
              .where((cat) => cat.toLowerCase().contains(text))
              .toList();
      showDropdown = text.isNotEmpty && filteredCategorias.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFieldInpute(
          textEditingController: widget.controller,
          hintText: widget.hintText,
          icon: widget.icon,
        ),
        if (showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children:
                  filteredCategorias.map((cat) {
                    return ListTile(
                      title: Text(cat),
                      onTap: () {
                        widget.controller.text = cat;
                        setState(() {
                          showDropdown = false;
                        });
                        FocusScope.of(context).unfocus();
                      },
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }
}

class EstabelecimentoSignUpScreen extends StatefulWidget {
  const EstabelecimentoSignUpScreen({super.key});

  @override
  State<EstabelecimentoSignUpScreen> createState() =>
      _EstabelecimentoSignUpScreenState();
}

class _EstabelecimentoSignUpScreenState
    extends State<EstabelecimentoSignUpScreen> {
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
  final Map<String, TextEditingController> horarioControllers = {
    'domingo': TextEditingController(),
    'segunda': TextEditingController(),
    'terca': TextEditingController(),
    'quarta': TextEditingController(),
    'quinta': TextEditingController(),
    'sexta': TextEditingController(),
    'sabado': TextEditingController(),
  };

  final Map<String, bool> fechadoDias = {
    'domingo': false,
    'segunda': false,
    'terca': false,
    'quarta': false,
    'quinta': false,
    'sexta': false,
    'sabado': false,
  };

  final Map<String, bool> vinteQuatroHorasDias = {
    'domingo': false,
    'segunda': false,
    'terca': false,
    'quarta': false,
    'quinta': false,
    'sexta': false,
    'sabado': false,
  };

  final Map<String, TextEditingController> horarioInicioControllers = {
    'domingo': TextEditingController(),
    'segunda': TextEditingController(),
    'terca': TextEditingController(),
    'quarta': TextEditingController(),
    'quinta': TextEditingController(),
    'sexta': TextEditingController(),
    'sabado': TextEditingController(),
  };

  final Map<String, TextEditingController> horarioFimControllers = {
    'domingo': TextEditingController(),
    'segunda': TextEditingController(),
    'terca': TextEditingController(),
    'quarta': TextEditingController(),
    'quinta': TextEditingController(),
    'sexta': TextEditingController(),
    'sabado': TextEditingController(),
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

  void signUpEstabelecimento() async {
    setState(() {
      isLoading = true;
    });

    // ***** ALTERAÇÃO PRINCIPAL: REMOVA O "as String" *****
    String res = await EstabelecimentoAuthService().signUpEstabelecimento(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      name: nameController.text.trim(),
      categoria: categoriaController.text.trim(),
      cnpj: cnpjController.text.trim(),
      celular: celularController.text.trim(),
      estado: estadoController.text.trim(),
      cidade: cidadeController.text.trim(),
      horarios: horarioInicioControllers.map((dia, controller) {
        // Agora o nome `horarioControllers` estava errado
        return MapEntry(
          dia,
          {
            'inicio': horarioInicioControllers[dia]!.text.trim(),
            'fim': horarioFimControllers[dia]!.text.trim(),
            'fechado': fechadoDias[dia]!,
            'vinteQuatroHoras': vinteQuatroHorasDias[dia]!,
          },
          // A conversão "as String" foi removida daqui!
        );
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (res == "success") {
      // ... (seu código continua igual)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const EstabelecimentoSuccessScreen(),
        ),
      );
    } else {
      showSnackBar(context, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: height / 4,
                  child: Image.asset("assets/images/estabelecimento.png"),
                ),
                const Text(
                  "Cadastro",
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Horário de funcionamento:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                /*for (var dia in horarioControllers.keys)
                  TextFieldInpute(
                    textEditingController: horarioControllers[dia]!,
                    hintText: "${dia[0].toUpperCase()}${dia.substring(1)}: *",
                    icon: Icons.access_time,
                  ),*/
                // ...existing code...
                for (var dia in horarioInicioControllers.keys)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${dia[0].toUpperCase()}${dia.substring(1)}:",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: fechadoDias[dia],
                              onChanged: (value) {
                                setState(() {
                                  fechadoDias[dia] = value!;
                                  if (value) {
                                    vinteQuatroHorasDias[dia] = false;
                                    horarioInicioControllers[dia]!.text = '';
                                    horarioFimControllers[dia]!.text = '';
                                  }
                                });
                              },
                            ),
                            const Text("Fechado"),
                            Checkbox(
                              value: vinteQuatroHorasDias[dia],
                              onChanged: (value) {
                                setState(() {
                                  vinteQuatroHorasDias[dia] = value!;
                                  if (value) {
                                    fechadoDias[dia] = false;
                                    horarioInicioControllers[dia]!.text =
                                        '00:00';
                                    horarioFimControllers[dia]!.text = '23:59';
                                  } else {
                                    horarioInicioControllers[dia]!.text = '';
                                    horarioFimControllers[dia]!.text = '';
                                  }
                                });
                              },
                            ),
                            const Text("24h"),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFieldInpute(
                                textEditingController:
                                    horarioInicioControllers[dia]!,
                                hintText: "Início",
                                icon: Icons.access_time,
                                enabled:
                                    !fechadoDias[dia]! &&
                                    !vinteQuatroHorasDias[dia]!,
                                inputFormatters: [HoraInputFormatter()],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFieldInpute(
                                textEditingController:
                                    horarioFimControllers[dia]!,
                                hintText: "Fechamento",
                                icon: Icons.access_time,
                                enabled:
                                    !fechadoDias[dia]! &&
                                    !vinteQuatroHorasDias[dia]!,
                                inputFormatters: [HoraInputFormatter()],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                TextFieldInpute(
                  textEditingController: emailController,
                  hintText: "E-mail *",
                  icon: Icons.email,
                ),
                TextFieldInpute(
                  textEditingController: passwordController,
                  hintText: "Senha *",
                  icon: Icons.lock,
                ),
                TextFieldInpute(
                  textEditingController: confirmPasswordController,
                  hintText: "Confirmação de Senha *",
                  icon: Icons.lock_outline,
                ),
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
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
