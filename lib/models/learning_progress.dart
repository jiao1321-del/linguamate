import 'daily_training.dart';
import 'learning_ability.dart';

class LearningProgressReport {
  final List<DailyTrainingSummary> history;
  final LearningAbilityReport abilityReport;
  final int activeMistakeCount;

  const LearningProgressReport({
    required this.history,
    required this.abilityReport,
    required this.activeMistakeCount,
  });

  int get totalSessions => history.length;

  int get totalTasks =>
      history.fold(0, (sum, item) => sum + item.totalTasks);

  int get totalCorrect =>
      history.fold(0, (sum, item) => sum + item.correctTasks);

  int get overallAccuracy =>
      totalTasks == 0 ? 0 : ((totalCorrect / totalTasks) * 100).round();

  int get completedDays => latestPerDay.length;

  List<DailyTrainingSummary> get latestPerDay {
    final byDate = <String, DailyTrainingSummary>{};
    for (final item in history) {
      final existing = byDate[item.dateKey];
      if (existing == null ||
          item.completedAt.isAfter(existing.completedAt)) {
        byDate[item.dateKey] = item;
      }
    }
    final values = byDate.values.toList(growable: false)
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return values;
  }

  int streakAt(DateTime now) {
    final keys = latestPerDay.map((item) => item.dateKey).toSet();
    if (keys.isEmpty) return 0;

    var cursor = DateTime(now.year, now.month, now.day);
    if (!keys.contains(DailyTrainingSummary.keyFor(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (keys.contains(DailyTrainingSummary.keyFor(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int last7DaysTasks(DateTime now) {
    final threshold = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    return latestPerDay
        .where((item) => !item.completedAt.toLocal().isBefore(threshold))
        .fold(0, (sum, item) => sum + item.totalTasks);
  }

  Map<String, int> get typeTotals {
    final result = <String, int>{};
    for (final summary in history) {
      summary.typeTotals.forEach((key, value) {
        result[key] = (result[key] ?? 0) + value;
      });
    }
    return result;
  }

  Map<String, int> get typeCorrect {
    final result = <String, int>{};
    for (final summary in history) {
      summary.typeCorrect.forEach((key, value) {
        result[key] = (result[key] ?? 0) + value;
      });
    }
    return result;
  }

  int typeAccuracy(String type) {
    final total = typeTotals[type] ?? 0;
    if (total == 0) return 0;
    return (((typeCorrect[type] ?? 0) / total) * 100).round();
  }
}
