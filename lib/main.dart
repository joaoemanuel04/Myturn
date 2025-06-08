// Myturn/lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myturn/Cliente_Login_Sign_up/login.dart';
import 'package:myturn/pages/cliente/editar_perfi.dart';
import 'package:myturn/pages/cliente/fila_ativa.dart';
import 'package:myturn/pages/cliente/perfil_cliente.dart';
import 'package:myturn/pages/cliente/reservas.dart';
import 'package:myturn/pages/cliente/home_cliente.dart'; // Certifique-se de importar a HomeScreen
import 'package:myturn/pages/estabelecimento/estabelecimento_home_screen.dart';
import 'package:myturn/services/deep_link_service.dart';
import 'package:myturn/services/notification_service.dart';
import 'pages/splash_page.dart'; // Sua SplashPage original
import 'package:myturn/pages/initial_router.dart'; // O novo InitialRouterPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await deepLinkService.init(); // Inicializa o serviço de deep link
  await NotificationService().initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color corPrimaria = Color(0xFF2C7DA0);
    const Color corFundoClaro = Color(0xFFF1F7F8);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyTurn',
      theme: ThemeData(
        primaryColor: corPrimaria,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: corPrimaria,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: corPrimaria,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: corPrimaria,
          background: corFundoClaro,
        ),
        useMaterial3: true,
      ),
      // --- ROTAS ATUALIZADAS ---
      routes: {
        '/': (context) => const InitialRouterPage(), // <--- Nova rota inicial
        '/splash_original':
            (context) => const SplashPage(), // <--- Sua SplashPage original
        '/home':
            (context) => const HomeScreen(), // Adicione a rota para HomeScreen
        '/login': (context) => const LoginScreen(),
        // Rota para a FilaAtivaScreen, garantindo que o argumento seja uma String
        '/fila_ativa': (context) {
          final Object? args = ModalRoute.of(context)?.settings.arguments;
          if (args is String && args.isNotEmpty) {
            return FilaAtivaScreen(
              estabelecimentoId: args,
              nomeEstabelecimento:
                  "Carregando...", // O nome real será carregado na tela
            );
          } else {
            // Se o argumento for inválido, redireciona para a home
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/home');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
        '/perfil': (context) => PerfilScreen(),
        '/reservas': (context) => MinhasReservasScreen(),
        '/editar_perfil': (context) => EditarPerfilScreen(),
        '/estabelecimento_home': (context) => const EstabelecimentoHomeScreen(),
        // Se você tiver uma rota específica para o login de estabelecimento
        // '/estabelecimento_login': (context) => const EstabelecimentoLoginScreen(),
      },
    );
  }
}
