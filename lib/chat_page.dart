import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_interviewer/core/env.dart';
import 'package:auto_interviewer/model/message.dart';
import 'package:auto_interviewer/repository/repository.dart';
import 'package:auto_interviewer/service/api/anthropic_client.dart';
import 'package:auto_interviewer/service/socket/stream_audio_source.dart';
import 'package:auto_interviewer/service/socket/web_socket_client.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Repository repository = Repository(
    webSocketClient: WebSocketClient(
      apiKey: Env.getInstance().elevenlabApiKey,
    ),
    anthropicClient: AnthropicClient(
      apiKey: Env.getInstance().anthropicApiKey,
    ),
  );
  final player = AudioPlayer();

  StreamController<String> controller = StreamController<String>();

  final ConcatenatingAudioSource _concatenatingAudioSource =
      ConcatenatingAudioSource(children: []);

  final messageHistory = <Message>[];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    player.dispose();
    controller.close();
    super.dispose();
  }

  void chat({required String userContent}) async {
    repository.startWebSocket();
    messageHistory.add(Message(role: 'user', content: userContent));
    const systemContent =
        "You are a podcast guest. You are a deep, philosophical thinker and currently in a conversation with another curious spirit. You are oriented around truthful, scientific, and philosophical thinking but you always add a touch of speculation and imagination to your thoughts as well as humor. You speak directly and practically and don't ramble on with niceties and generalizations. You talk in specifics and can often disagree too. please keep your responses brief and to the point. try to never respond beyond 50 words unless the user asks for more elaboration. please be conversational and engaging. do not return any emotional indicators like *chuckles* or anything. just respond with your thoughts only. Your goal is not to always agree but to bring interesting and unique perspectives. stay away from cliches";
    final res = await repository.createMessage(
      system: systemContent,
      messageHistory: messageHistory,
    );

    repository.sendPayloadSocket(
      {
        'text': ' ',
        'voice_settings': {
          "stability": 0.6,
          "similarity_boost": 0.8,
        },
        "generation_config": {
          "chunk_length_schedule": [150, 190, 280, 320]
        },
        "xi_api_key": Env.getInstance().elevenlabApiKey,
      },
    );
    String assistantResponse = '';

    res.fold(
      (l) => print(l),
      (r) {
        r.listen((text) {
          assistantResponse += text;
          controller.add(assistantResponse);
          repository.sendPayloadSocket({
            "text": text,
            "try_trigger_generation": true,
          });
        }).onDone(() async {
          messageHistory.add(
            Message(
              role: 'assistant',
              content: assistantResponse,
            ),
          );
          repository.sendPayloadSocket({
            "text": "",
          });
        });
      },
    );

    _concatenatingAudioSource.clear();

    repository.audioUpdates().listen(
      (event) {
        _concatenatingAudioSource.add(CustomStreamAudioSource(bytes: event));
        // Play audio here
        // "event" is the audio stream chunk
      },
    );

    await playAudio();
    await stopAudio();
  }

  Future<void> playAudio() async {
    await player.setAudioSource(_concatenatingAudioSource);
    await player.play();
  }

  Future<void> stopAudio() async {
    repository.stopWebSocket();
    if (player.playing) {
      await player.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Chat Screen'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                chat(userContent: 'Hello');
              },
              child: Text(player.playing ? 'Stop' : 'Play'),
            ),
            StreamBuilder(
              stream: controller.stream,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    return const Text('None');
                  case ConnectionState.waiting:
                    return const Text('Waiting');
                  case ConnectionState.active:
                    return Text(snapshot.data ?? '');
                  case ConnectionState.done:
                    return Text(snapshot.data ?? '');
                  default:
                    return const Text('None');
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
