MyTurn: Sistema de Gerenciamento de Filas Digitais
Evite filas, otimize seu tempo.
MyTurn é uma plataforma digital que atua como um intermediário inteligente entre estabelecimentos e clientes, substituindo a espera física por uma experiência virtual mais cômoda, transparente e eficiente.

O Problema
Filas de espera em estabelecimentos comerciais e de serviços são uma fonte de perda de tempo e frustração. A espera prolongada deteriora a experiência do cliente e pode levar à desistência do serviço , enquanto a gestão manual de filas é ineficiente e sujeita a erros.



A Solução: MyTurn
O MyTurn foi criado para resolver esse problema, oferecendo uma solução de baixo custo para modernizar o atendimento e melhorar a experiência do cliente.


Para Clientes: Permite entrar na fila remotamente e acompanhar sua posição em tempo real.


Para Estabelecimentos: Oferece um painel de controle para gerenciar a fila, chamar clientes e gerar um QR Code para facilitar a entrada na fila.


Funcionalidades
Cliente

Autenticação: Login com E-mail/Senha e Google.


Busca: Visualização de estabelecimentos próximos, com filtros por categoria e nome.


Fila Virtual: Entrada remota em filas e acompanhamento da posição em tempo real.


Notificações: Recebimento de alertas quando a vez estiver próxima.


Reservas: Visualização e gerenciamento de reservas ativas, com a opção de sair da fila.

Estabelecimento

Autenticação: Sistema de cadastro e login exclusivo.


Painel de Controle: Ferramenta para visualização e gerenciamento completo da fila.


Status da Fila: Funcionalidade para abrir e fechar a fila para novas entradas.


Chamada de Clientes: Mecanismo para chamar o próximo cliente da fila.


QR Code: Geração de QR Code para facilitar a entrada de clientes na fila.

Arquitetura e Tecnologias
O projeto foi construído com uma arquitetura moderna e escalável:


Frontend (Multiplataforma): Flutter e Dart.


Backend (BaaS - Backend as a Service): Firebase.


Autenticação: Firebase Authentication.


Banco de Dados: Firebase Realtime Database.


Notificações e Lógica de Servidor: Cloud Functions e Firebase Cloud Messaging (FCM).

Geolocalização: Google Maps Platform.

Pontos Fortes e Fracos
Pontos Fortes

Multiplataforma: O uso do Flutter permite alcançar um público amplo (iOS e Android) com um desenvolvimento otimizado.


Experiência em Tempo Real: A integração com o Firebase Realtime Database proporciona uma experiência de usuário fluida e instantânea.


Baixo Custo de Infraestrutura: A utilização do Firebase como BaaS reduz os custos e a complexidade de gerenciamento de servidores.

Pontos a Melhorar

Gerenciamento de Estado: O uso exclusivo de setState pode se tornar um gargalo de manutenibilidade à medida que o aplicativo cresce.


Ausência de Testes Automatizados: O projeto não possui uma suíte de testes (unitários, de widget e de integração), o que pode dificultar a manutenção a longo prazo.

Trabalhos Futuros

Agendamento de Horário: Permitir que clientes agendem um horário específico.


Painel de Métricas Avançado: Oferecer aos estabelecimentos um dashboard com dados como tempo médio de espera e horários de pico.


Sistema de Avaliação: Permitir que os clientes avaliem os estabelecimentos após o atendimento.


Gerenciamento de Estado Avançado: Adotar soluções como Provider ou BLoC.

Autores
João Emanuel

Rebeka Beatriz
