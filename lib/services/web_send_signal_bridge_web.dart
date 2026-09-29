import 'dart:async';
import 'dart:js_interop';

@JS('window.addEventListener')
external void _addWindowEventListener(JSString type, JSFunction listener);

@JS('window.removeEventListener')
external void _removeWindowEventListener(JSString type, JSFunction listener);

class WebSendSignalBridge {
  const WebSendSignalBridge();

  Stream<void> get events {
    final controller = StreamController<void>();
    final JSFunction listener = ((JSAny? _) {
      controller.add(null);
    }).toJS;

    _addWindowEventListener('linguamate-send-signal'.toJS, listener);
    controller.onCancel = () {
      _removeWindowEventListener('linguamate-send-signal'.toJS, listener);
    };
    return controller.stream;
  }
}
