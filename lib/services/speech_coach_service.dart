import 'speech_coach_api.dart';
import 'speech_coach_service_stub.dart'
    if (dart.library.html) 'speech_coach_service_web.dart' as implementation;

export 'speech_coach_api.dart';

SpeechCoachService createSpeechCoachService() =>
    implementation.createSpeechCoachService();
