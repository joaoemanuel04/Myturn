import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myturn/services/deep_link_service.dart';
import 'dart:async';

// Importe as telas de destino
import 'package:myturn/pages/cliente/home_cliente.dart';
import 'package:myturn/pages/estabelecimento/estabelecimento_home_screen.dart';
import 'package:myturn/pages/cliente/fila_ativa.dart';
import 'package:myturn/pages/splash_page.dart';

// Importe nosso novo serviço
import 'package:myturn/services/user_type_service.dart';

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
    // Um pequeno delay para a inicialização do app
    await Future.delayed(const Duration(milliseconds: 500));

    // Se o widget não estiver mais na tela, não faz nada
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // CASO 1: O USUÁRIO ESTÁ LOGADO
      // Vamos verificar o tipo de usuário
      final userType = await UserTypeService.getUserType(user.uid);

      if (!mounted) return;

      if (userType == UserType.client) {
        // É um cliente, redireciona para a área do cliente
        final String? pendingEstablishmentId =
            deepLinkService.pendingEstablishmentId;
        if (pendingEstablishmentId != null &&
            pendingEstablishmentId.isNotEmpty) {
          deepLinkService.pendingEstablishmentId = null; // Usa o link e o limpa
          // Navega para a home e depois para a fila
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => FilaAtivaScreen(
                    estabelecimentoId: pendingEstablishmentId,
                    nomeEstabelecimento: "Carregando...",
                  ),
            ),
          );
        } else {
          // Navegação normal para a home do cliente
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else if (userType == UserType.establishment) {
        // É um estabelecimento, redireciona para a área do estabelecimento
        Navigator.of(context).pushReplacementNamed('/estabelecimento_home');
      } else {
        // Anomalia: usuário autenticado mas sem registro no DB. Deslogar.
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushReplacementNamed('/splash_original');
      }
    } else {
      // CASO 2: O USUÁRIO NÃO ESTÁ LOGADO
      // Simplesmente vai para a tela de seleção inicial
      Navigator.of(context).pushReplacementNamed('/splash_original');
    }

    // Ouve por deep links que cheguem enquanto o app já está aberto
    _deepLinkSubscription = deepLinkService.linkStream.listen((
      establishmentId,
    ) {
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => FilaAtivaScreen(
                  estabelecimentoId: establishmentId,
                  nomeEstabelecimento: "Carregando...",
                ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostra uma tela de carregamento enquanto a lógica de roteamento acontece
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
