// Myturn/lib/pages/splash_page.dart (VERSÃO ORIGINAL RESTAURADA)

import 'package:flutter/material.dart';
import 'package:myturn/Cliente_Login_Sign_up/login.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/estabelecimento_login.dart';

enum TipoLogin { cliente, estabelecimento }

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Set<TipoLogin> selection = {TipoLogin.cliente};

  void _navegar() {
    final rota =
        selection.first == TipoLogin.cliente
            ? MaterialPageRoute(builder: (context) => const LoginScreen())
            : MaterialPageRoute(
              builder: (context) => const EstabelecimentoLoginScreen(),
            );
    Navigator.push(context, rota);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Image.asset('assets/images/logo.png', height: 150),
              const SizedBox(height: 20),
              const Text(
                'MyTurn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF012A4A),
                ),
              ),
              const Text(
                'Evite filas, otimize seu tempo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const Spacer(flex: 3),
              const Text(
                'ENTRAR COMO:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black45,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<TipoLogin>(
                segments: const <ButtonSegment<TipoLogin>>[
                  ButtonSegment<TipoLogin>(
                    value: TipoLogin.cliente,
                    label: Text('Cliente'),
                    icon: Icon(Icons.person_outline),
                  ),
                  ButtonSegment<TipoLogin>(
                    value: TipoLogin.estabelecimento,
                    label: Text('Estabelecimento'),
                    icon: Icon(Icons.storefront_outlined),
                  ),
                ],
                selected: selection,
                onSelectionChanged: (Set<TipoLogin> newSelection) {
                  setState(() {
                    if (newSelection.isNotEmpty) {
                      selection = newSelection;
                    }
                  });
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.7),
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _navegar,
                child: const Text('Prosseguir'),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
