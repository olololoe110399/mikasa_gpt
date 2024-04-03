import 'package:mikasa_gpt/model/message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messageListProvider = NotifierProvider<MessageList, List<Message>>(
  MessageList.new,
);

class MessageList extends Notifier<List<Message>> {
  @override
  List<Message> build() => [];

  void add(String role, String content, {int? timestamp}) {
    state = [
      ...state,
      Message(
        timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
        role: role,
        content: content,
      ),
    ];
  }

  void edit({required int timestamp, required String content}) {
    state = [
      for (final message in state)
        if (message.timestamp == timestamp)
          Message(
            timestamp: message.timestamp,
            role: message.role,
            content: content,
          )
        else
          message,
    ];
  }

  void remove(Message target) {
    state = state
        .where((message) => message.timestamp != target.timestamp)
        .toList();
  }
}
