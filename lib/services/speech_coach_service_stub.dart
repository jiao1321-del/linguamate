import 'speech_coach_api.dart';

SpeechCoachService createSpeechCoachService() =>
    const UnsupportedSpeechCoachService();

class UnsupportedSpeechCoachService implements SpeechCoachService {
  const UnsupportedSpeechCoachService();

  @override
  bool get canListen => false;

  @override
  bool get canSpeak => false;

  @override
  Future<String?> listen({
    required String languageTag,
  }) async =>
      null;

  @override
  Future<void> speak({
    required String text,
    required String languageTag,
  }) async {}

  @override
  void stop() {}
}
