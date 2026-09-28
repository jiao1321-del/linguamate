import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'speech_coach_api.dart';

export 'speech_coach_api.dart';

SpeechCoachService createSpeechCoachService() =>
    PluginSpeechCoachService();

class PluginSpeechCoachService implements SpeechCoachService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  bool get canSpeak => true;

  @override
  bool get canListen => true;

  @override
  Future<void> speak({
    required String text,
    required String languageTag,
    double rate = 0.46,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return;

    await _tts.stop();
    await _tts.setLanguage(languageTag);
    await _tts.setSpeechRate(rate.clamp(0.25, 0.65));
    await _tts.awaitSpeakCompletion(true);
    await _tts.setPitch(1.02);
    await _tts.speak(normalized);
  }

  @override
  Future<String?> listen({
    required String languageTag,
  }) async {
    final completer = Completer<String?>();
    String? latest;

    final available = await _speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') &&
            !completer.isCompleted) {
          completer.complete(latest);
        }
      },
      onError: (_) {
        if (!completer.isCompleted) completer.complete(latest);
      },
    );

    if (!available) return null;

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: languageTag,
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
      ),
      onResult: (result) {
        final value = result.recognizedWords.trim();
        if (value.isNotEmpty) latest = value;
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(latest);
        }
      },
    );

    final result = await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => latest,
    );

    await _speech.stop();
    return result?.trim().isEmpty == true ? null : result?.trim();
  }

  @override
  void stop() {
    unawaited(_tts.stop());
    unawaited(_speech.stop());
  }
}
