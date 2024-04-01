import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:auto_interviewer/core/env.dart';
import 'package:auto_interviewer/helper/stream.dart';
import 'package:auto_interviewer/model/message.dart';
import 'package:auto_interviewer/model/sse_message.dart';
import 'package:auto_interviewer/service/api/anthropic_client.dart';
import 'package:auto_interviewer/service/api/error_mapper.dart';
import 'package:auto_interviewer/service/socket/web_socket_client.dart';
import 'package:dartz/dartz.dart';

class Repository {
  final WebSocketClient webSocketClient;
  final AnthropicClient anthropicClient;

  Repository({
    required this.webSocketClient,
    required this.anthropicClient,
  });

  void startWebSocket() {
    final uri =
        "wss://api.elevenlabs.io/v1/text-to-speech/${Env.getInstance().voiceId}/stream-input?optimize_streaming_latency=2&model_id=eleven_turbo_v2";
    webSocketClient.connect(uri);
  }

  void sendPayloadSocket(Map<String, dynamic> payload) {
    webSocketClient.send(jsonEncode(payload));
  }

  Stream<Uint8List> audioUpdates() {
    return webSocketClient.audioUpdates();
  }

  Future<Either<String, Stream<String>>> createMessage({
    required List<Message> messageHistory,
    String? system,
  }) async {
    try {
      final response = await anthropicClient.createMessage(
        messageHistory: messageHistory,
        system: system,
      );

      return Right(
        response
            .transform(unit8Transformer)
            .transform(const Utf8Decoder())
            .transform(const LineSplitter())
            .transform(const SseTransformer())
            .transform(
          StreamTransformer.fromHandlers(
            handleData: (SseMessage message, EventSink<String> sink) {
              if (message.event == 'content_block_delta') {
                sink.add(jsonDecode(message.data)['delta']['text'] as String);
              }
            },
          ),
        ),
      );
    } catch (e) {
      return Left(ErrorMapper.mapError(e));
    }
  }

  void stopWebSocket() {
    webSocketClient.disconnect();
  }
}
