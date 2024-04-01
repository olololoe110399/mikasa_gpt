import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketClient {
  IOWebSocketChannel? channel;
  final String apiKey;

  late StreamController<Uint8List> byteStreamController;

  WebSocketClient({
    required this.apiKey,
  });

  void _initializeControllers() {
    byteStreamController = StreamController<Uint8List>.broadcast();
  }

  void connect(
    String url, {
    Map<String, String>? headers,
  }) {
    if (channel != null && channel!.closeCode == null) {
      debugPrint('Already connected');
      return;
    }
    _initializeControllers();
    debugPrint('Connecting to the server...');
    channel = IOWebSocketChannel.connect(url, headers: headers);
    channel!.stream.listen(
      (event) {
        Map<String, dynamic> message = jsonDecode(event);
        if (message['audio'] != null && message['audio'] is String) {
          final audioChunk = base64Decode(message['audio'] as String);
          final uni8list = Uint8List.fromList(audioChunk);
          byteStreamController.add(uni8list);
        }
      },
      onDone: () {
        debugPrint('Connection closed');
      },
      onError: (error) {
        debugPrint('Error: $error');
      },
    );
  }

  void send(String data) {
    if (channel == null || channel!.closeCode != null) {
      debugPrint('Not connected');
      return;
    }
    channel!.sink.add(data);
  }

  Stream<Uint8List> audioUpdates() {
    return byteStreamController.stream;
  }

  void disconnect() {
    if (channel == null || channel!.closeCode != null) {
      debugPrint('Not connected');
      return;
    }
    channel!.sink.close();

    byteStreamController.close();
  }
}
