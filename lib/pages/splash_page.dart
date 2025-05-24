import 'package:flutter/material.dart';
import 'package:myturn/Cliente_Login_Sign_up/login.dart';
import 'package:myturn/Cliente_Login_Sign_up/sign_up.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool isClientSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Parte de cima com logo
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFFE8F1F3),
              child: Center(
                child: Image.asset('assets/images/logo.png', width: 300),
              ),
            ),
          ),

          // Parte de baixo com texto e botões
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: const Text(
                      'MyTurn',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(221, 10, 10, 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 160),
                  const Text(
                    'entrar como:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F7F8),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade400,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isClientSelected = true;
                              });
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color:
                                    isClientSelected
                                        ? const Color(0xFF2C7DA0)
                                        : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Cliente',
                                  style: TextStyle(
                                    color:
                                        isClientSelected
                                            ? Colors.white
                                            : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isClientSelected = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color:
                                    !isClientSelected
                                        ? const Color(0xFF2C7DA0)
                                        : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Estabelecimento',
                                  style: TextStyle(
                                    color:
                                        !isClientSelected
                                            ? Colors.white
                                            : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
