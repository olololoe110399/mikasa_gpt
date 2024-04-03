import 'dart:async';
import 'dart:typed_data';

import 'package:mikasa_gpt/helper/sse_event_sink.dart';
import 'package:mikasa_gpt/model/sse_message.dart';

StreamTransformer<Uint8List, List<int>> unit8Transformer =
    StreamTransformer.fromHandlers(
  handleData: (data, sink) {
    sink.add(List<int>.from(data));
  },
);

class SseTransformer extends StreamTransformerBase<String, SseMessage> {
  const SseTransformer();
  @override
  Stream<SseMessage> bind(Stream<String> stream) {
    return Stream.eventTransformed(stream, (sink) => SseEventSink(sink));
  }
}

extension TextChunkerExtension on Stream<String> {
  Stream<String> chunkText() async* {
    final splitters = {
      ".",
      ",",
      "?",
      "!",
      ";",
      ":",
      "—",
      "-",
      "(",
      ")",
      "[",
      "]",
      "}",
      " "
    };
    var buffer = "";

    await for (var text in this) {
      if (splitters.contains(buffer.substring(buffer.length - 1))) {
        yield "$buffer ";
        buffer = text;
      } else if (splitters.contains(text.substring(0, 1))) {
        yield "$buffer${text[0]} ";
        buffer = text.substring(1);
      } else {
        buffer += text;
      }
    }

    if (buffer.isNotEmpty) {
      yield "$buffer ";
    }
  }
}
