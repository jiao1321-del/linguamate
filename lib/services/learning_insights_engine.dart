import '../models/daily_training.dart';
import '../models/learning_ability.dart';
import '../models/learning_insights.dart';
import '../models/learning_progress.dart';
import '../models/mistake_record.dart';
import '../models/speaking_attempt.dart';
import '../models/training_telemetry.dart';

class LearningInsightsEngine {
  const LearningInsightsEngine._();

  static LearningInsightsSnapshot build({
    required LearningProgressReport progress,
    required List<LearningAbilityRecord> abilities,
    required List<MistakeRecord> mistakes,
    required List<SpeakingAttempt> speaking,
    required List<TrainingTelemetry> telemetry,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final day = DateTime(reference.year, reference.month, reference.day);
    final start7 = day.subtract(const Duration(days: 6));
    final start30 = day.subtract(const Duration(days: 29));
    final olderStart = day.subtract(const Duration(days: 29));
    final olderEnd = day.subtract(const Duration(days: 7));

    final recent7 = progress.latestPerDay
        .where((item) => !item.completedAt.toLocal().isBefore(start7))
        .toList(growable: false);
    final recent30 = progress.latestPerDay
        .where((item) => !item.completedAt.toLocal().isBefore(start30))
        .toList(growable: false);
    final older = progress.latestPerDay.where((item) {
      final date = item.completedAt.toLocal();
      return !date.isBefore(olderStart) && date.isBefore(olderEnd);
    }).toList(growable: false);

    final tasks7 = _sumTasks(recent7);
    final tasks30 = _sumTasks(recent30);
    final correct7 = _sumCorrect(recent7);
    final correct30 = _sumCorrect(recent30);
    final accuracy7 = tasks7 == 0 ? 0 : ((correct7 / tasks7) * 100).round();
    final accuracy30 =
        tasks30 == 0 ? 0 : ((correct30 / tasks30) * 100).round();

    final speaking30 = speaking
        .where((item) => !item.recordedAt.toLocal().isBefore(start30))
        .toList(growable: false);
    final speakingAverage = speaking30.isEmpty
        ? 0
        : (speaking30.fold<int>(0, (sum, item) => sum + item.score) /
                speaking30.length)
            .round();

    final telemetry30 = telemetry
        .where((item) => !item.recordedAt.toLocal().isBefore(start30))
        .toList(growable: false);
    final trackedMs =
        telemetry30.fold<int>(0, (sum, item) => sum + item.responseMs);
    final untrackedTasks = (tasks30 - telemetry30.length).clamp(0, tasks30);
    final estimatedMinutes30 =
        ((trackedMs + untrackedTasks * 45000) / 60000).round();

    final activeMistakes = mistakes.where((item) => item.isActive).toList()
      ..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
    final topMistake = activeMistakes.isEmpty
        ? '目前沒有高優先錯題'
        : activeMistakes.first.title.trim().isEmpty
            ? activeMistakes.first.prompt
            : activeMistakes.first.title;

    var staleAbility = '近期能力都有練習';
    if (abilities.isNotEmpty) {
      final stale = [...abilities]
        ..sort((a, b) => a.lastPracticedAt.compareTo(b.lastPracticedAt));
      final days = day.difference(stale.first.lastPracticedAt.toLocal()).inDays;
      staleAbility = days <= 7
          ? '${stale.first.label} · $days 天前'
          : '${stale.first.label} · 已 $days 天沒練';
    }

    final recentAcc = _typeAccuracy(recent7);
    final olderAcc = _typeAccuracy(older);
    var fastest = '資料累積中';
    var bestDelta = -999;
    for (final entry in recentAcc.entries) {
      final previous = olderAcc[entry.key];
      if (previous == null) continue;
      final delta = entry.value - previous;
      if (delta > bestDelta) {
        bestDelta = delta;
        fastest = '${_typeLabel(entry.key)} ${delta >= 0 ? '+' : ''}$delta%';
      }
    }

    final trend = accuracy7 - accuracy30;
    final weeklyReport = tasks7 == 0
        ? '這週還沒有訓練紀錄。先完成一組短訓練，Shili 才能開始比較趨勢。'
        : '近 7 天完成 $tasks7 題、答對率 $accuracy7%。'
            '${trend > 0 ? '近期準確度比 30 天平均高 $trend%。' : trend < 0 ? '近期準確度比 30 天平均低 ${trend.abs()}%，適合先補弱點。' : '近期表現與 30 天平均一致。'}';

    final next = <String>[
      if (activeMistakes.isNotEmpty) '先處理錯題：$topMistake',
      if (staleAbility.contains('已 ')) '重新喚醒：$staleAbility',
      if (speakingAverage == 0)
        '建立本週第一次口說基準'
      else if (speakingAverage < 80)
        '口說平均 $speakingAverage 分，安排一次 Shadowing',
      if (tasks7 < 20) '本週再完成 ${20 - tasks7} 題建立穩定節奏',
    ];
    if (next.isEmpty) {
      next.addAll([
        '進入情境實戰，把已掌握內容用出來',
        '完成本週 Checkpoint',
        '提高下一組自適應難度',
      ]);
    }

    return LearningInsightsSnapshot(
      tasks7: tasks7,
      tasks30: tasks30,
      days7: recent7.length,
      days30: recent30.length,
      accuracy7: accuracy7,
      accuracy30: accuracy30,
      estimatedMinutes30: estimatedMinutes30,
      speakingAverage: speakingAverage,
      fastestImproving: fastest,
      staleAbility: staleAbility,
      topMistake: topMistake,
      weeklyReport: weeklyReport,
      nextActions: next.take(3).toList(growable: false),
    );
  }

  static int _sumTasks(List<DailyTrainingSummary> items) =>
      items.fold(0, (sum, item) => sum + item.totalTasks);

  static int _sumCorrect(List<DailyTrainingSummary> items) =>
      items.fold(0, (sum, item) => sum + item.correctTasks);

  static Map<String, int> _typeAccuracy(List<DailyTrainingSummary> items) {
    final total = <String, int>{};
    final correct = <String, int>{};
    for (final item in items) {
      item.typeTotals.forEach(
        (key, value) => total[key] = (total[key] ?? 0) + value,
      );
      item.typeCorrect.forEach(
        (key, value) => correct[key] = (correct[key] ?? 0) + value,
      );
    }
    return {
      for (final entry in total.entries)
        if (entry.value > 0)
          entry.key:
              (((correct[entry.key] ?? 0) / entry.value) * 100).round(),
    };
  }

  static String _typeLabel(String type) => switch (type) {
        'vocabulary' => '單字・片語',
        'grammar' => '文法',
        'weakness' => '弱點',
        'review' => 'SRS',
        'speaking' => '口說',
        _ => type,
      };
}
