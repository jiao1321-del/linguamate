// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import 'speech_coach_api.dart';

SpeechCoachService createSpeechCoachService() =>
    BrowserSpeechCoachService();

class BrowserSpeechCoachService implements SpeechCoachService {
  @override
  bool get canSpeak => html.window.speechSynthesis != null;

  @override
  bool get canListen =>
      js.context.hasProperty('SpeechRecognition') ||
      js.context.hasProperty('webkitSpeechRecognition');

  @override
  Future<void> speak({
    required String text,
    required String languageTag,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty || !canSpeak) return;

    final synthesis = html.window.speechSynthesis;
    synthesis?.cancel();

    final utterance = html.SpeechSynthesisUtterance(normalized)
      ..lang = languageTag
      ..rate = 0.92
      ..pitch = 1.02;

    synthesis?.speak(utterance);
  }

  @override
  Future<String?> listen({
    required String languageTag,
  }) async {
    final constructor = js.context['SpeechRecognition'] ??
        js.context['webkitSpeechRecognition'];
    if (constructor is! js.JsFunction) return null;

    final completer = Completer<String?>();
    final recognition = js.JsObject(constructor)
      ..['lang'] = languageTag
      ..['continuous'] = false
      ..['interimResults'] = false
      ..['maxAlternatives'] = 1;

    void complete(String? value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    recognition['onresult'] = js.allowInterop((dynamic event) {
      try {
        final results = event['results'];
        final firstResult = results[0];
        final firstAlternative = firstResult[0];
        final transcript = firstAlternative['transcript']?.toString().trim();
        complete(
          transcript == null || transcript.isEmpty ? null : transcript,
        );
      } catch (_) {
        complete(null);
      }
    });

    recognition['onerror'] = js.allowInterop((dynamic _) => complete(null));
    recognition['onend'] = js.allowInterop((dynamic _) => complete(null));

    try {
      recognition.callMethod('start');
    } catch (_) {
      complete(null);
    }

    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        try {
          recognition.callMethod('stop');
        } catch (_) {}
        return null;
      },
    );
  }

  @override
  void stop() {
    html.window.speechSynthesis?.cancel();
  }
}
