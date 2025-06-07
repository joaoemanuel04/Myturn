// lib/services/deep_link_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart'; // <--- Mudança aqui: importamos o app_links

class DeepLinkService {
  // Usaremos um StreamController para "transmitir" o ID do estabelecimento
  // para qualquer parte do app que esteja ouvindo.
  final StreamController<String> _linkController =
      StreamController<String>.broadcast();

  // Getter para que outras partes do app possam ouvir o stream
  Stream<String> get linkStream => _linkController.stream;

  // Variável para armazenar o ID do estabelecimento que precisa ser processado
  String? pendingEstablishmentId;

  // Instância de AppLinks para usar suas funcionalidades
  final _appLinks = AppLinks(); // <--- Nova instância de AppLinks

  Future<void> init() async {
    // Escuta por links que abram o app enquanto ele já está rodando
    // Agora usamos _appLinks.uriLinkStream
    _appLinks.uriLinkStream.listen(
      // <--- Mudança aqui: usando a instância de AppLinks
      (Uri? uri) {
        if (uri != null) {
          _handleUri(uri);
        }
      },
      onError: (err) {
        print('Erro ao ouvir o stream de links: $err');
      },
    );

    // Pega o link inicial que abriu o app (se ele estava fechado)
    // Agora usamos _appLinks.getInitialLink()
    try {
      final Uri? initialUri =
          await _appLinks
              .getInitialLink(); // <--- Mudança aqui: usando a instância de AppLinks
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } on PlatformException {
      print('Erro ao obter o link inicial.');
    }
  }

  void _handleUri(Uri uri) {
    // Verifica se o link corresponde ao nosso padrão
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'fila') {
      final establishmentId = uri.queryParameters['id'];
      if (establishmentId != null && establishmentId.isNotEmpty) {
        print("Deep Link recebido! ID do Estabelecimento: $establishmentId");

        // Armazena o ID para ser usado após o login
        pendingEstablishmentId = establishmentId;

        // Emite o ID para qualquer listener ativo
        _linkController.add(establishmentId);
      }
    }
  }

  // Descarta o controller quando não for mais necessário
  void dispose() {
    _linkController.close();
  }
}

// Cria uma instância global do serviço para fácil acesso
final deepLinkService = DeepLinkService();
