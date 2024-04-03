import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatInput extends HookConsumerWidget {
  final TextEditingController controller;
  final Function(String?) onSubmitted;
  final FocusNode? keyboardFocusNode;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.keyboardFocusNode,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecording = useState(false);
    useEffect(() {
      isRecording.value = controller.text.isEmpty;
      controller.addListener(() {
        isRecording.value = controller.text.isEmpty;
      });
      return null;
    }, []);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: TextField(
                focusNode: keyboardFocusNode ?? FocusNode(),
                controller: controller,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(8, 0, 0, 8),
                  hintText: "Message",
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w100,
                    height: 1.0,
                  ),
                ),
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  height: 1.0,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            iconSize: 20,
            onPressed: () {
              onSubmitted(controller.text);
            },
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: Icon(
              isRecording.value
                  ? Icons.headphones_rounded
                  : Icons.arrow_upward_rounded,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}
