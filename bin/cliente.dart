import 'dart:async';
import 'dart:convert';

import 'dart:html';

class ReceiveThread {
  final WebSocket socket;
  final _messageController = StreamController<String>();

  ReceiveThread(this.socket);

  void start() async {
    try {
      await for (final event in socket.onMessage) {
        final message = jsonDecode(event.data)['message'];
        _messageController.add(message);
      }
    } catch (e) {
      print('Erro ao receber mensagens: $e');
    }
  }

  Stream<String> get messageStream => _messageController.stream;
}

void runInThread(dynamic runnable) {
  runZoned(() {
    runnable.start();
  }, onError: (error, stackTrace) {
    print('Erro na thread: $error\n$stackTrace');
  });
}

void main() {
  final socket = WebSocket('ws://localhost:9544/ws');

  socket.onOpen.listen((event) {
    print('Conexão estabelecida com sucesso!');
  });

  final receiveThread = ReceiveThread(socket);
  runInThread(receiveThread);

  final input = querySelector('#input') as InputElement;
  final sendButton = querySelector('#send-button') as ButtonElement;
  final chatBox = querySelector('#chat-box') as DivElement;

  sendButton.onClick.listen((_) {
    final message = input.value.trim();
    socket.send(jsonEncode({'message': message}));
    input.value = '';
  });

  receiveThread.messageStream.listen((message) {
    final messageDiv = DivElement()..text = message;
    chatBox.append(messageDiv);
  });
}
