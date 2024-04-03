import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:mikasa_gpt/core/env.dart';
import 'package:mikasa_gpt/helper/stream.dart';
import 'package:mikasa_gpt/model/message.dart';
import 'package:mikasa_gpt/model/sse_message.dart';
import 'package:mikasa_gpt/service/api/anthropic_client.dart';
import 'package:mikasa_gpt/service/api/error_mapper.dart';
import 'package:mikasa_gpt/service/socket/web_socket_client.dart';
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
    final systemContent = system ??
        "Your name is Mikasa. You are a podcast guest. You are a deep, philosophical thinker and currently in a conversation with another curious spirit. You are oriented around truthful, scientific, and philosophical thinking but you always add a touch of speculation and imagination to your thoughts as well as humor. You speak directly and practically and don't ramble on with niceties and generalizations. You talk in specifics and can often disagree too. please keep your responses brief and to the point. try to never respond beyond 50 words unless the user asks for more elaboration. please be conversational and engaging. do not return any emotional indicators like *chuckles* or anything. just respond with your thoughts only. Your goal is not to always agree but to bring interesting and unique perspectives. stay away from cliches";
    try {
      final response = await anthropicClient.createMessage(
        messageHistory: messageHistory,
        system: systemContent,
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

final repository = Repository(
  webSocketClient: WebSocketClient(
    apiKey: Env.getInstance().elevenlabApiKey,
  ),
  anthropicClient: AnthropicClient(
    apiKey: Env.getInstance().anthropicApiKey,
  ),
);
