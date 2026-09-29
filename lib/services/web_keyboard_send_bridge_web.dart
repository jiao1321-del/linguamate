import 'dart:async';
import 'dart:js_interop';

@JS('window.addEventListener')
external void _addWindowEventListener(JSString type, JSFunction listener);

@JS('window.removeEventListener')
external void _removeWindowEventListener(JSString type, JSFunction listener);

class WebKeyboardSendBridge {
  const WebKeyboardSendBridge();

  Stream<void> get events {
    final controller = StreamController<void>();
    final JSFunction listener = ((JSAny? _) {
      controller.add(null);
    }).toJS;

    _addWindowEventListener('linguamate-keyboard-send'.toJS, listener);
    controller.onCancel = () {
      _removeWindowEventListener('linguamate-keyboard-send'.toJS, listener);
    };
    return controller.stream;
  }
}
