// Myturn/lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myturn/Cliente_Login_Sign_up/login.dart';
import 'package:myturn/pages/cliente/editar_perfi.dart';
import 'package:myturn/pages/cliente/perfil_cliente.dart';
import 'package:myturn/pages/cliente/reservas.dart';
import 'pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      routes: {
        //'/': (context) => const TestPageOne(),
        '/': (context) => const SplashPage(),
        '/perfil': (context) => PerfilScreen(),
        '/reservas': (context) => MinhasReservasScreen(),
        '/login': (context) => const LoginScreen(),
        '/editar_perfil': (context) => EditarPerfilScreen(),
      },
    );
  }
}
