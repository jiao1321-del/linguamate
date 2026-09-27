abstract class SpeechCoachService {
  bool get canSpeak;
  bool get canListen;

  Future<void> speak({
    required String text,
    required String languageTag,
  });

  Future<String?> listen({
    required String languageTag,
  });

  void stop();
}
