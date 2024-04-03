import 'package:flutter/material.dart';

class Bubble extends StatefulWidget {
  final String message;
  final bool isMe;
  final String time;
  final String name;
  final String uri;

  const Bubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
    required this.name,
    required this.uri,
  });

  @override
  State<Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<Bubble> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            widget.name,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Row(
            mainAxisAlignment:
                widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!widget.isMe)
                CircleAvatar(
                  backgroundImage: AssetImage(
                    widget.uri,
                  ),
                ),
              const SizedBox(width: 10),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                ),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isMe
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: widget.isMe
                        ? const Radius.circular(12)
                        : const Radius.circular(0),
                    bottomRight: widget.isMe
                        ? const Radius.circular(0)
                        : const Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.isMe ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      widget.time,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (widget.isMe)
                CircleAvatar(
                  backgroundImage: AssetImage(
                    widget.uri,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
