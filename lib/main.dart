import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myturn/Cliente_Login_Sign_up/login.dart';
import 'package:myturn/pages/cliente/editar_perfi.dart';
import 'package:myturn/pages/cliente/perfil_cliente.dart';
import 'package:myturn/pages/cliente/reservas.dart';
import 'pages/splash_page.dart';
//import 'package:myturn/Cliente_Login_Sign_up/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyTurn',
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: {
        '/': (context) => SplashPage(),
        '/perfil': (context) => PerfilScreen(),
        '/reservas': (context) => MinhasReservasScreen(),
        '/login': (context) => LoginScreen(),
        '/editar_perfil': (context) => EditarPerfilScreen(),
      },
    );
  }
}
