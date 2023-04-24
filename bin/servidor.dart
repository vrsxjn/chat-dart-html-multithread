import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() {
  HttpServer.bind(InternetAddress.loopbackIPv4, 9544).then((server) {
    print('Servidor rodando na porta ${server.port}');

    var clients = <WebSocket, String>{};

    server.listen((request) {
      if (request.uri.path == '/ws') {
        WebSocketTransformer.upgrade(request).then((socket) {
          print(
              'Cliente conectado: ${request.connectionInfo.remoteAddress.address}:${request.connectionInfo.remotePort}');

          clients[socket] =
              "${request.connectionInfo.remoteAddress.address}:${request.connectionInfo.remotePort}";

          socket.listen((message) {
            print('Mensagem recebida: $message');

            var senderIP = clients[socket];

            for (var client in clients.keys) {
              client.add(json.encode({'name': senderIP, 'message': message}));
            }
          }, onDone: () {
            print('Cliente desconectado!');
            clients.remove(socket);
          });
        });
      } else {
        var file = File(
            'C:/Users/virus/Desktop/java/dart/chat-dart/bin/web/chat.html');
        file.exists().then((exists) async {
          if (exists) {
            request.response.headers.contentType = ContentType.html;
            try {
              await file.openRead().pipe(request.response).catchError((e) {
                print('Erro ao enviar arquivo: $e');
                request.response.close();
              });
            } catch (e) {
              print('Erro ao enviar arquivo: $e');
              request.response.close();
            }
          } else {
            request.response.statusCode = HttpStatus.notFound;
            request.response.write('Página não encontrada');
            request.response.close();
          }
        });
      }
    });
  });
}
