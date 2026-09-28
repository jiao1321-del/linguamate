import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/adaptive_learning.dart';
import '../models/speaking_attempt.dart';

class SpeakingHistoryStore {
  static const _key = 'speaking_history_v133';

  const SpeakingHistoryStore();

  Future<List<SpeakingAttempt>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final attempts = decoded
          .whereType<Map>()
          .map(
            (item) => SpeakingAttempt.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);
      attempts.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return attempts;
    } catch (_) {
      return const [];
    }
  }

  Future<List<SpeakingAttempt>> append(
    PronunciationAssessment assessment, {
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final current = await load();
    final updated = [
      SpeakingAttempt(
        id: timestamp.microsecondsSinceEpoch.toString(),
        recordedAt: timestamp,
        target: assessment.target,
        transcript: assessment.transcript,
        completeness: assessment.completeness,
        fluency: assessment.fluency,
        score: assessment.score,
        missingWords: assessment.missingWords,
      ),
      ...current,
    ];
    final capped =
        updated.length <= 100 ? updated : updated.take(100).toList();
    await replace(capped);
    return capped;
  }

  Future<void> replace(List<SpeakingAttempt> attempts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(attempts.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
