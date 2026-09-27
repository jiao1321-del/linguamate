import '../models/learning_ability.dart';
import '../models/mistake_record.dart';
import '../models/weakness_record.dart';

class LearningAbilityAnalyzer {
  const LearningAbilityAnalyzer._();

  static LearningAbilityReport build({
    required List<LearningAbilityRecord> tracked,
    required List<MistakeRecord> mistakes,
    required List<WeaknessRecord> weaknesses,
  }) {
    final records = <String, LearningAbilityRecord>{
      for (final item in tracked) item.key: item,
    };

    for (final mistake in mistakes) {
      final task = mistake.toTask();
      final identity = LearningAbilityRecord.identityFor(task);
      if (records.containsKey(identity.key)) continue;

      final attempts = mistake.wrongCount + mistake.correctStreak;
      if (attempts <= 0) continue;

      records[identity.key] = LearningAbilityRecord(
        key: identity.key,
        label: identity.label,
        type: mistake.type,
        attempts: attempts,
        correctCount: mistake.correctStreak,
        wrongCount: mistake.wrongCount,
        correctStreak: mistake.correctStreak,
        lastResultCorrect: mistake.lastCorrectAt != null &&
                mistake.lastCorrectAt!.isAfter(mistake.lastWrongAt)
            ? true
            : false,
        lastPracticedAt: mistake.lastCorrectAt != null &&
                mistake.lastCorrectAt!.isAfter(mistake.lastWrongAt)
            ? mistake.lastCorrectAt!
            : mistake.lastWrongAt,
      );
    }

    for (final weakness in weaknesses) {
      final label = weakness.category.trim();
      if (label.isEmpty) continue;
      final key = 'weakness:${label.toLowerCase()}';
      if (records.containsKey(key)) continue;

      records[key] = LearningAbilityRecord(
        key: key,
        label: label,
        type: 'weakness',
        attempts: weakness.count,
        correctCount: 0,
        wrongCount: weakness.count,
        correctStreak: 0,
        lastResultCorrect: false,
        lastPracticedAt: weakness.lastSeenAt,
      );
    }

    return LearningAbilityReport(
      records: records.values.toList(growable: false),
    );
  }
}
