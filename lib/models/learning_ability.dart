import 'daily_training.dart';

enum AbilityStatus {
  mastered,
  learning,
  needsWork,
}

class LearningAbilityRecord {
  final String key;
  final String label;
  final String type;
  final int attempts;
  final int correctCount;
  final int wrongCount;
  final int correctStreak;
  final bool? lastResultCorrect;
  final DateTime lastPracticedAt;

  const LearningAbilityRecord({
    required this.key,
    required this.label,
    required this.type,
    required this.attempts,
    required this.correctCount,
    required this.wrongCount,
    required this.correctStreak,
    required this.lastPracticedAt,
    this.lastResultCorrect,
  });

  double get accuracy => attempts == 0 ? 0 : correctCount / attempts;

  int get score {
    if (attempts == 0) return 0;
    final accuracyScore = accuracy * 80;
    final experienceScore = (attempts.clamp(0, 5) / 5) * 20;
    return (accuracyScore + experienceScore)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  AbilityStatus get status {
    if (attempts >= 5 && accuracy >= 0.8 && correctStreak >= 2) {
      return AbilityStatus.mastered;
    }
    if (attempts >= 2 && (accuracy < 0.6 || wrongCount > correctCount)) {
      return AbilityStatus.needsWork;
    }
    return AbilityStatus.learning;
  }

  String get statusLabel => switch (status) {
        AbilityStatus.mastered => '已掌握',
        AbilityStatus.learning => '學習中',
        AbilityStatus.needsWork => '待加強',
      };

  LearningAbilityRecord recordResult({
    required bool correct,
    required DateTime now,
  }) {
    return LearningAbilityRecord(
      key: key,
      label: label,
      type: type,
      attempts: attempts + 1,
      correctCount: correctCount + (correct ? 1 : 0),
      wrongCount: wrongCount + (correct ? 0 : 1),
      correctStreak: correct ? correctStreak + 1 : 0,
      lastResultCorrect: correct,
      lastPracticedAt: now,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'type': type,
        'attempts': attempts,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'correctStreak': correctStreak,
        'lastResultCorrect': lastResultCorrect,
        'lastPracticedAt': lastPracticedAt.toIso8601String(),
      };

  factory LearningAbilityRecord.fromJson(Map<String, dynamic> json) {
    return LearningAbilityRecord(
      key: (json['key'] as String? ?? '').trim(),
      label: (json['label'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? 'review').trim(),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrongCount'] as num?)?.toInt() ?? 0,
      correctStreak: (json['correctStreak'] as num?)?.toInt() ?? 0,
      lastResultCorrect: json['lastResultCorrect'] as bool?,
      lastPracticedAt:
          DateTime.tryParse(json['lastPracticedAt'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static LearningAbilityRecord fromTask(
    DailyTrainingTask task, {
    required bool correct,
    required DateTime now,
  }) {
    final identity = identityFor(task);
    return LearningAbilityRecord(
      key: identity.key,
      label: identity.label,
      type: task.type,
      attempts: 1,
      correctCount: correct ? 1 : 0,
      wrongCount: correct ? 0 : 1,
      correctStreak: correct ? 1 : 0,
      lastResultCorrect: correct,
      lastPracticedAt: now,
    );
  }

  static AbilityIdentity identityFor(DailyTrainingTask task) {
    switch (task.type) {
      case 'vocabulary':
        return const AbilityIdentity(
          key: 'vocabulary',
          label: '單字・片語',
        );
      case 'grammar':
        final label = _detailFromTitle(task.title, '文法加強');
        return AbilityIdentity(
          key: 'grammar:${label.toLowerCase()}',
          label: label,
        );
      case 'weakness':
        final label = _detailFromTitle(task.title, '弱點加強');
        return AbilityIdentity(
          key: 'weakness:${label.toLowerCase()}',
          label: label,
        );
      case 'review':
        return const AbilityIdentity(
          key: 'review',
          label: 'SRS 記憶',
        );
      default:
        return AbilityIdentity(
          key: task.type,
          label: task.title.trim().isEmpty ? '綜合練習' : task.title.trim(),
        );
    }
  }

  static String _detailFromTitle(String title, String fallback) {
    final parts = title.split('·');
    if (parts.length > 1) {
      final detail = parts.sublist(1).join('·').trim();
      if (detail.isNotEmpty) return detail;
    }
    return fallback;
  }
}

class AbilityIdentity {
  final String key;
  final String label;

  const AbilityIdentity({
    required this.key,
    required this.label,
  });
}

class LearningAbilityReport {
  final List<LearningAbilityRecord> records;

  const LearningAbilityReport({
    required this.records,
  });

  int get masteredCount =>
      records.where((item) => item.status == AbilityStatus.mastered).length;

  int get learningCount =>
      records.where((item) => item.status == AbilityStatus.learning).length;

  int get needsWorkCount =>
      records.where((item) => item.status == AbilityStatus.needsWork).length;

  int get totalAttempts =>
      records.fold(0, (sum, item) => sum + item.attempts);

  int get totalCorrect =>
      records.fold(0, (sum, item) => sum + item.correctCount);

  int get totalWrong =>
      records.fold(0, (sum, item) => sum + item.wrongCount);

  int get overallAccuracy =>
      totalAttempts == 0 ? 0 : ((totalCorrect / totalAttempts) * 100).round();

  LearningAbilityRecord? get priority {
    if (records.isEmpty) return null;
    final sorted = [...records]..sort(_priorityCompare);
    return sorted.first;
  }

  String? get priorityType => priority?.type;

  String? get priorityLabel => priority?.label;

  List<LearningAbilityRecord> get ranked {
    final sorted = [...records]..sort(_priorityCompare);
    return sorted;
  }

  static int _priorityCompare(
    LearningAbilityRecord a,
    LearningAbilityRecord b,
  ) {
    final statusCompare =
        _statusPriority(a.status).compareTo(_statusPriority(b.status));
    if (statusCompare != 0) return statusCompare;

    final scoreCompare = a.score.compareTo(b.score);
    if (scoreCompare != 0) return scoreCompare;

    return b.lastPracticedAt.compareTo(a.lastPracticedAt);
  }

  static int _statusPriority(AbilityStatus status) => switch (status) {
        AbilityStatus.needsWork => 0,
        AbilityStatus.learning => 1,
        AbilityStatus.mastered => 2,
      };
}
