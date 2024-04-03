import 'package:mikasa_gpt/ui/widget/chat_input.dart';
import 'package:mikasa_gpt/ui/widget/chat_listview.dart';
import 'package:mikasa_gpt/provider/message_provider.dart';
import 'package:mikasa_gpt/repository/repository.dart';
import 'package:mikasa_gpt/ui/page/voice_page.dart';
import 'package:mikasa_gpt/ui/widget/example_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends StatefulHookConsumerWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  FocusNode keyboardFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final textTheme = Theme.of(context).textTheme;
    bool isConversationStarted = ref.watch(messageListProvider).isNotEmpty;
    return GestureDetector(
      onTap: () {
        keyboardFocusNode.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("MikasaGPT"),
          actions: [
            if (isConversationStarted)
              PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      child: const Text("Settings"),
                      onTap: () {
                        keyboardFocusNode.unfocus();
                      },
                    ),
                    PopupMenuItem(
                      child: const Text("Help"),
                      onTap: () {
                        keyboardFocusNode.unfocus();
                      },
                    ),
                  ];
                },
              ),
          ],
        ),
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    if (isConversationStarted) const SizedBox(height: 38),
                    if (!isConversationStarted)
                      Expanded(
                        child: Center(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              Image.asset(
                                "assets/images/bot.png",
                                height: 200,
                              ),
                              Text(
                                "Welcome to\nMikasaGPT",
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        "Oni-chan, I can help you with anything you want to know. Just ask me anything!",
                                        style: textTheme.bodyMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Icon(Icons.wb_sunny_outlined),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Examples",
                                      style: textTheme.titleMedium?.copyWith(
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const ExampleWidget(
                                      text:
                                          "“What are some good books to read?”",
                                    ),
                                    const ExampleWidget(
                                      text:
                                          "“Got any creative ideas for a 10 year old’s birthday?”",
                                    ),
                                    const ExampleWidget(
                                      text:
                                          "“How do I make a good impression on a first date?”",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Expanded(
                        child: ChatListView(),
                      ),
                    ChatInput(
                      keyboardFocusNode: keyboardFocusNode,
                      controller: controller,
                      onSubmitted: (question) async {
                        controller.clear();
                        keyboardFocusNode.unfocus();
                        if (question != null && question.isNotEmpty) {
                          ref.read(messageListProvider.notifier).add(
                                'user',
                                question,
                              );

                          final res = await repository.createMessage(
                            messageHistory: ref.read(messageListProvider),
                          );
                          final timestamp =
                              DateTime.now().millisecondsSinceEpoch;
                          ref
                              .read(
                                messageListProvider.notifier,
                              )
                              .add(
                                'assistant',
                                '',
                                timestamp: timestamp,
                              );

                          res.fold(
                            (l) => print(l),
                            (r) {
                              String assistantResponse = '';
                              r.listen((text) {
                                assistantResponse += text;
                                ref
                                    .read(
                                      messageListProvider.notifier,
                                    )
                                    .edit(
                                      timestamp: timestamp,
                                      content: assistantResponse,
                                    );
                              });
                            },
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VoicePage(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16)
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
