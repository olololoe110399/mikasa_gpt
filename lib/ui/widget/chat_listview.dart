import 'package:mikasa_gpt/ui/widget/bubble.dart';
import 'package:mikasa_gpt/provider/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatListView extends HookConsumerWidget {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageList = ref.watch(messageListProvider);
    return ListView.builder(
      itemCount: messageList.length,
      itemBuilder: (context, index) {
        final message = messageList[index];
        return Bubble(
          message: message.content,
          isMe: message.isMe,
          time: message.time,
          name: message.name,
          uri: message.uri,
        );
      },
    );
  }
}
