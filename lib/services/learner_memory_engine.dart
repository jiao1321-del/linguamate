import '../models/ai_chat_state.dart';
import '../models/learner_memory_profile.dart';
import '../models/learning_ability.dart';
import '../models/learning_item.dart';
import '../models/mistake_record.dart';
import '../models/speaking_attempt.dart';
import '../models/weakness_record.dart';

class LearnerMemoryEngine {
  const LearnerMemoryEngine._();

  static LearnerMemoryProfile build({
    required List<LearningAbilityRecord> abilities,
    required List<WeaknessRecord> weaknesses,
    required List<MistakeRecord> mistakes,
    required List<SpeakingAttempt> speaking,
    required List<LearningItem> savedItems,
    AiChatState? chatState,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();

    final mastered = abilities
        .where((item) => _decayedScore(item, reference) >= 80)
        .toList()
      ..sort((a, b) =>
          _decayedScore(b, reference).compareTo(_decayedScore(a, reference)));

    final weak = abilities
        .where((item) => _decayedScore(item, reference) < 65)
        .toList()
      ..sort((a, b) =>
          _decayedScore(a, reference).compareTo(_decayedScore(b, reference)));

    final stale = abilities
        .where(
          (item) => reference.difference(item.lastPracticedAt).inDays >= 21,
        )
        .toList()
      ..sort((a, b) => a.lastPracticedAt.compareTo(b.lastPracticedAt));

    final activeMistakes = mistakes.where((item) => item.isActive).toList()
      ..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));

    final wordCounts = <String, int>{};
    for (final attempt in speaking.take(20)) {
      for (final raw in attempt.missingWords) {
        final word = raw.trim().toLowerCase();
        if (word.isEmpty) continue;
        wordCounts[word] = (wordCounts[word] ?? 0) + 1;
      }
    }
    final rankedWords = wordCounts.entries.toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        return count != 0 ? count : a.key.compareTo(b.key);
      });

    final masteredLabels =
        mastered.take(5).map((item) => item.label).toList(growable: false);
    final weakLabels = <String>{
      ...weak.take(5).map((item) => item.label),
      ...weaknesses.take(3).map((item) => item.category),
    }.where((item) => item.trim().isNotEmpty).take(6).toList(growable: false);
    final staleLabels =
        stale.take(4).map((item) => item.label).toList(growable: false);
    final mistakeLabels = activeMistakes
        .take(4)
        .map((item) => item.title.trim().isEmpty ? item.prompt : item.title)
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
    final speakingWords =
        rankedWords.take(5).map((item) => item.key).toList(growable: false);
    final preferredScenario = chatState?.scenario.trim().isNotEmpty == true
        ? chatState!.scenario.trim()
        : '自由對話';

    final parts = <String>[
      if (masteredLabels.isNotEmpty) '已掌握：${masteredLabels.join('、')}',
      if (weakLabels.isNotEmpty) '目前弱點：${weakLabels.join('、')}',
      if (staleLabels.isNotEmpty) '久未練習：${staleLabels.join('、')}',
      if (mistakeLabels.isNotEmpty)
        '常見錯題：${mistakeLabels.join('、')}',
      if (speakingWords.isNotEmpty)
        '口說常漏字：${speakingWords.join('、')}',
      '收藏 ${savedItems.length} 句',
      '偏好情境：$preferredScenario',
    ];

    return LearnerMemoryProfile(
      updatedAt: reference,
      masteredSkills: masteredLabels,
      weakSkills: weakLabels,
      staleSkills: staleLabels,
      commonMistakes: mistakeLabels,
      speakingWeakWords: speakingWords,
      preferredScenario: preferredScenario,
      summary: parts.join('；'),
    );
  }

  static int _decayedScore(
    LearningAbilityRecord ability,
    DateTime now,
  ) {
    final inactiveDays =
        now.difference(ability.lastPracticedAt).inDays.clamp(0, 365);
    final decay = (inactiveDays ~/ 7) * 3;
    return (ability.score - decay).clamp(0, 100).toInt();
  }
}
