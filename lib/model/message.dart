import 'package:flutter/foundation.dart' show immutable;

@immutable
class Message {
  final int timestamp;
  final String role;
  final String content;

  const Message({
    required this.timestamp,
    required this.role,
    required this.content,
  });

  String get uri =>
      role == 'user' ? 'assets/images/user.png' : 'assets/images/bot2.png';

  String get name => role == 'user' ? 'You' : 'Mikasa';

  bool get isMe => role == 'user' ? true : false;

  String get time {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      timestamp: int.tryParse(json['timestamp']) ?? 0,
      role: json['role'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}
