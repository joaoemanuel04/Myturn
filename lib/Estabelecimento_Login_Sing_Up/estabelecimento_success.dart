import 'package:flutter/material.dart';
import 'package:myturn/Estabelecimento_Login_Sing_Up/estabelecimento_login.dart';

class EstabelecimentoSuccessScreen extends StatelessWidget {
  const EstabelecimentoSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Cadastro realizado com sucesso!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const EstabelecimentoLoginScreen(),
                  ),
                );
              },
              child: const Text("Ir para o login"),
            ),
          ],
        ),
      ),
    );
  }
}
