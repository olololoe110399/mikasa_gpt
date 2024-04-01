import 'dart:async';

import 'package:auto_interviewer/model/sse_message.dart';

class SseEventSink implements EventSink<String> {
  final EventSink<SseMessage> _eventSink;

  String? _id;
  String _event = "message";
  String _data = "";
  int? _retry;

  SseEventSink(this._eventSink);

  @override
  void add(String event) {
    if (event.startsWith("id:")) {
      _id = event.substring(3).trim();
      return;
    }
    if (event.startsWith("event:")) {
      _event = event.substring(6).trim();
      return;
    }
    if (event.startsWith("data:")) {
      _data = event.substring(5).trim();
      return;
    }
    if (event.startsWith("retry:")) {
      _retry = int.tryParse(event.substring(6).trim());
      return;
    }
    if (event.isEmpty) {
      _eventSink
          .add(SseMessage(id: _id, event: _event, data: _data, retry: _retry));
      _id = null;
      _event = "message";
      _data = "";
      _retry = null;
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _eventSink.addError(error, stackTrace);
  }

  @override
  void close() {
    _eventSink.close();
  }
}
