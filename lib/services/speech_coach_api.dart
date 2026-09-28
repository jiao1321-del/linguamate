abstract class SpeechCoachService {
  bool get canSpeak;
  bool get canListen;

  Future<void> speak({
    required String text,
    required String languageTag,
    double rate = 0.46,
  });

  Future<String?> listen({
    required String languageTag,
  });

  void stop();
}
