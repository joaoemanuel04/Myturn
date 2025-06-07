// lib/pages/initial_router.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myturn/services/deep_link_service.dart';
import 'dart:async';

// Importe a HomeScreen para poder navegar para ela como base
import 'package:myturn/pages/cliente/home_cliente.dart';
import 'package:myturn/pages/cliente/fila_ativa.dart';
import 'package:myturn/Cliente_Login_Sign_up/login.dart';
import 'package:myturn/pages/splash_page.dart';

class InitialRouterPage extends StatefulWidget {
  const InitialRouterPage({super.key});

  @override
  State<InitialRouterPage> createState() => _InitialRouterPageState();
}

class _InitialRouterPageState extends State<InitialRouterPage> {
  StreamSubscription<String>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _navigateAfterInit();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _navigateAfterInit() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final String? pendingEstablishmentId =
        deepLinkService.pendingEstablishmentId;

    // Lógica para decidir para onde navegar e substituir a InitialRouterPage
    if (pendingEstablishmentId != null && pendingEstablishmentId.isNotEmpty) {
      // CASO 1: App foi aberto via Deep Link (QR Code)
      if (isLoggedIn) {
        // Usuário logado e com deep link:
        // 1. Limpa a pilha e define HomeScreen como a base.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false, // Remove todas as rotas anteriores
        );
        // 2. Agora, empilha a FilaAtivaScreen no topo da HomeScreen.
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => FilaAtivaScreen(
                  estabelecimentoId: pendingEstablishmentId,
                  nomeEstabelecimento:
                      "Carregando...", // Nome será carregado na tela
                ),
          ),
        );
        // Limpa o ID pendente APENAS AQUI, pois ele foi consumido.
        deepLinkService.pendingEstablishmentId = null;
      } else {
        // Usuário NÃO logado e com deep link: vai para a SplashPage original.
        // O ID do estabelecimento PERMANECE em deepLinkService.pendingEstablishmentId
        // para ser usado APÓS o login bem-sucedido na LoginScreen.
        Navigator.of(context).pushReplacementNamed('/splash_original');
      }
    } else {
      // CASO 2: App foi aberto normalmente (sem deep link inicial)
      if (isLoggedIn) {
        // Usuário logado: vai para a HomeScreen
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Usuário NÃO logado: vai para a SplashPage original.
        Navigator.of(context).pushReplacementNamed('/splash_original');
      }
    }

    // 3. Começa a escutar por deep links subsequentes (quando o app já está rodando)
    _deepLinkSubscription = deepLinkService.linkStream.listen((
      establishmentId,
    ) {
      // Quando um novo deep link chega, empilha a FilaAtivaScreen
      // (não substitua, para que o usuário possa voltar para a tela anterior)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => FilaAtivaScreen(
                estabelecimentoId: establishmentId,
                nomeEstabelecimento:
                    "Carregando...", // Nome será carregado na tela
              ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
