import 'dart:async';

class TextChuner implements EventSink<String> {
  final EventSink<String> _eventSink;

  TextChuner(this._eventSink);

  @override
  void add(String event) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _eventSink.addError(error, stackTrace);
  }

  @override
  void close() {
    _eventSink.close();
  }
}
