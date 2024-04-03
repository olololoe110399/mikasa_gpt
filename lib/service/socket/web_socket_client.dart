import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketClient {
  IOWebSocketChannel? channel;
  final String apiKey;

  late StreamController<Uint8List> byteStreamController;

  WebSocketClient({
    required this.apiKey,
  }) {
    _initializeControllers();
  }

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
          _convertBase64ToUint8ListInBackground(message['audio'] as String);
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

  void _convertBase64ToUint8ListInBackground(String base64String) {
    ReceivePort receivePort = ReceivePort();
    Isolate.spawn(_decodeBase64InIsolate, {
      'base64String': base64String,
      'sendPort': receivePort.sendPort,
    });
    receivePort.listen((dynamic decodedData) {
      if (decodedData is Uint8List) {
        byteStreamController.add(decodedData);
      }
    });
  }

  static void _decodeBase64InIsolate(Map<String, dynamic> message) {
    String base64String = message['base64String'];
    SendPort sendPort = message['sendPort'];
    Uint8List bytes = base64Decode(base64String);
    sendPort.send(bytes);
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

    _initializeControllers();
  }
}
