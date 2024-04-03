import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:mikasa_gpt/core/env.dart';
import 'package:mikasa_gpt/provider/message_provider.dart';
import 'package:mikasa_gpt/repository/repository.dart';
import 'package:mikasa_gpt/service/socket/stream_audio_source.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:synchronized/synchronized.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class VoicePage extends StatefulHookConsumerWidget {
  const VoicePage({super.key});

  @override
  ConsumerState<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends ConsumerState<VoicePage> {
  final _speechToText = SpeechToText();
  final _player = AudioPlayer();
  final _lock = Lock();
  final _textController = StreamController<String>.broadcast();
  final _concatenatingAudioSource = ConcatenatingAudioSource(
    useLazyPreparation: true,
    children: [],
  );
  var lastWords = '';
  var isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    await initSpeechToText();
    await toggleButton();
    _player.playerStateStream.listen((event) {
      // check if the audio is completed
      if (event.processingState == ProcessingState.completed) {
        setState(() {
          isPlaying = false;
        });
        toggleButton();
      }
    });
  }

  Future<void> interrupt() async {
    await _player.stop();
    repository.stopWebSocket();
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _player.dispose();
    _textController.close();
    super.dispose();
  }

  Future<void> initSpeechToText() async {
    await _speechToText.initialize();
    setState(() {});
  }

  Future<void> startListening() async {
    await _speechToText.listen(onResult: onSpeechResult);
    setState(() {});
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
    });
  }

  Future<void> toggleButton() async {
    if (await _speechToText.hasPermission && _speechToText.isNotListening) {
      if (isPlaying) {
        await interrupt();
        setState(() {
          isPlaying = false;
        });
        toggleButton();
        return;
      }
      setState(() {
        lastWords = '';
      });
      await startListening();
    } else if (_speechToText.isListening) {
      await stopListening();
      if (lastWords.isNotEmpty) {
        chat(userContent: lastWords);
      } else {
        back();
      }
    } else {
      await initSpeechToText();
    }
  }

  void back() {
    Navigator.pop(context);
  }

  void chat({
    required String userContent,
  }) async {
    setState(() {
      isPlaying = true;
    });

    ref.read(messageListProvider.notifier).add(
          'user',
          userContent,
        );

    repository.startWebSocket();
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
    final res = await repository.createMessage(
      messageHistory: ref.read(messageListProvider),
    );

    res.fold(
      (l) => print(l),
      (r) {
        String assistantResponse = '';
        r.listen((text) {
          assistantResponse += text;
          _textController.add(assistantResponse);
          repository.sendPayloadSocket({
            "text": text,
            "try_trigger_generation": true,
          });
        }).onDone(() async {
          ref.read(messageListProvider.notifier).add(
                'assistant',
                assistantResponse,
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
        _lock.synchronized(() async {
          await _concatenatingAudioSource.add(
            CustomStreamAudioSource(bytes: event),
          );
        });
      },
    );

    await playAudio();
  }

  Future<void> playAudio() async {
    await _player.setAudioSource(_concatenatingAudioSource);
    await _player.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Name of chatbot AI
        title: Text(
          _speechToText.isListening ? 'You' : "Mikasa",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const SizedBox.shrink(),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ZoomIn(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(209, 243, 249, 1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    height: 123,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(
                          _speechToText.isListening
                              ? 'assets/images/user.png'
                              : 'assets/images/bot.png',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // chat bubble
            FadeInLeft(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 40).copyWith(
                  top: 30,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromRGBO(200, 200, 200, 1),
                  ),
                  borderRadius: BorderRadius.circular(20).copyWith(
                    topLeft: Radius.zero,
                  ),
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(209, 243, 249, 1),
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(
                                _speechToText.isListening
                                    ? 'assets/images/user.png'
                                    : 'assets/images/bot2.png',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _speechToText.isListening ? 'You' : 'Mikasa',
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: _speechToText.isListening
                            ? Text(
                                lastWords.isNotEmpty ? lastWords : '...',
                                style: const TextStyle(
                                  fontSize: 18,
                                  height: 1.0,
                                ),
                              )
                            : StreamBuilder(
                                stream: _textController.stream,
                                builder: (context, snapshot) {
                                  switch (snapshot.connectionState) {
                                    case ConnectionState.active:
                                    case ConnectionState.done:
                                      return Text(
                                        snapshot.data.toString(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          height: 1.0,
                                        ),
                                      );
                                    default:
                                      return const Text(
                                        'Thinking... ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          height: 1.0,
                                        ),
                                      );
                                  }
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FadeInUp(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _speechToText.isListening
                  ? (lastWords.isNotEmpty ? 'Tap to send' : 'Tap to back')
                  : 'Tap to interrupt',
              style: const TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            AvatarGlow(
              glowColor: Colors.blue,
              child: FloatingActionButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: _speechToText.isListening
                    ? (lastWords.isNotEmpty ? Colors.blue : Colors.red)
                    : Colors.red,
                onPressed: toggleButton,
                child: Icon(
                  _speechToText.isListening
                      ? (lastWords.isNotEmpty ? Icons.send : Icons.close)
                      : Icons.close,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
