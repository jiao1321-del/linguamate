import 'daily_training.dart';
import 'learning_progress.dart';

class LearningBadge {
  final String id;
  final String title;
  final String description;
  final bool unlocked;

  const LearningBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

class LearningCalendarDay {
  final DateTime date;
  final int tasks;
  final int correct;

  const LearningCalendarDay({
    required this.date,
    required this.tasks,
    required this.correct,
  });

  bool get completed => tasks > 0;

  int get accuracy =>
      tasks == 0 ? 0 : ((correct / tasks) * 100).round();
}

class LearningGrowthSnapshot {
  static const int xpPerLevel = 250;

  final int dailyGoal;
  final int todayTasks;
  final int xp;
  final int level;
  final int xpIntoLevel;
  final int streak;
  final int weeklyDays;
  final int weeklyTasks;
  final int weeklyCorrect;
  final int previousWeekTasks;
  final String? bestSkillLabel;
  final String? focusSkillLabel;
  final List<LearningBadge> badges;
  final List<LearningCalendarDay> calendar;

  const LearningGrowthSnapshot({
    required this.dailyGoal,
    required this.todayTasks,
    required this.xp,
    required this.level,
    required this.xpIntoLevel,
    required this.streak,
    required this.weeklyDays,
    required this.weeklyTasks,
    required this.weeklyCorrect,
    required this.previousWeekTasks,
    required this.bestSkillLabel,
    required this.focusSkillLabel,
    required this.badges,
    required this.calendar,
  });

  double get dailyGoalProgress =>
      dailyGoal <= 0 ? 0 : (todayTasks / dailyGoal).clamp(0, 1).toDouble();

  bool get dailyGoalCompleted => todayTasks >= dailyGoal;

  int get xpToNextLevel => xpPerLevel - xpIntoLevel;

  double get levelProgress =>
      (xpIntoLevel / xpPerLevel).clamp(0, 1).toDouble();

  int get unlockedBadgeCount =>
      badges.where((badge) => badge.unlocked).length;

  int get weeklyAccuracy =>
      weeklyTasks == 0 ? 0 : ((weeklyCorrect / weeklyTasks) * 100).round();

  int get weeklyTaskDelta => weeklyTasks - previousWeekTasks;

  String get weeklyTrendLabel {
    if (previousWeekTasks == 0 && weeklyTasks == 0) {
      return '這週還沒有訓練紀錄';
    }
    if (previousWeekTasks == 0) {
      return '這週已開始累積 $weeklyTasks 題';
    }
    if (weeklyTaskDelta > 0) {
      return '比前 7 天多 $weeklyTaskDelta 題';
    }
    if (weeklyTaskDelta < 0) {
      return '比前 7 天少 ${weeklyTaskDelta.abs()} 題';
    }
    return '和前 7 天一樣穩定';
  }

  factory LearningGrowthSnapshot.fromReport({
    required LearningProgressReport report,
    required DateTime now,
    required int dailyGoal,
  }) {
    final safeGoal = dailyGoal <= 0 ? 10 : dailyGoal;
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = DailyTrainingSummary.keyFor(today);
    DailyTrainingSummary? todaySummary;
    for (final item in report.latestPerDay) {
      if (item.dateKey == todayKey) {
        todaySummary = item;
        break;
      }
    }

    final latest = report.latestPerDay;
    final currentStart = today.subtract(const Duration(days: 6));
    final previousStart = today.subtract(const Duration(days: 13));

    final currentWeek = latest.where((item) {
      final date = _dateFromKey(item.dateKey);
      return date != null &&
          !date.isBefore(currentStart) &&
          !date.isAfter(today);
    }).toList(growable: false);

    final previousWeek = latest.where((item) {
      final date = _dateFromKey(item.dateKey);
      return date != null &&
          !date.isBefore(previousStart) &&
          date.isBefore(currentStart);
    }).toList(growable: false);

    final weeklyTasks =
        currentWeek.fold(0, (sum, item) => sum + item.totalTasks);
    final weeklyCorrect =
        currentWeek.fold(0, (sum, item) => sum + item.correctTasks);
    final previousWeekTasks =
        previousWeek.fold(0, (sum, item) => sum + item.totalTasks);

    final streak = report.streakAt(now);
    final speakingRecords = report.abilityReport.records
        .where((item) => item.type == 'speaking');
    final speakingAttempts = speakingRecords.fold(
      0,
      (sum, item) => sum + item.attempts,
    );
    final speakingCorrect = speakingRecords.fold(
      0,
      (sum, item) => sum + item.correctCount,
    );
    final xp = (report.totalCorrect * 10) +
        (report.totalTasks * 2) +
        (report.completedDays * 15) +
        (streak * 5) +
        (speakingAttempts * 4) +
        (speakingCorrect * 8);
    final level = (xp ~/ xpPerLevel) + 1;
    final xpIntoLevel = xp % xpPerLevel;

    String? bestSkillLabel;
    var bestAccuracy = -1;
    var bestAttempts = -1;
    for (final entry in report.typeTotals.entries) {
      if (entry.value <= 0) continue;
      final accuracy = report.typeAccuracy(entry.key);
      if (accuracy > bestAccuracy ||
          (accuracy == bestAccuracy && entry.value > bestAttempts)) {
        bestAccuracy = accuracy;
        bestAttempts = entry.value;
        bestSkillLabel = _typeLabel(entry.key);
      }
    }

    final badges = <LearningBadge>[
      LearningBadge(
        id: 'first-session',
        title: '正式起步',
        description: '完成第一次每日訓練',
        unlocked: report.completedDays >= 1,
      ),
      LearningBadge(
        id: 'streak-3',
        title: '連續 3 天',
        description: '連續學習 3 天',
        unlocked: streak >= 3,
      ),
      LearningBadge(
        id: 'streak-7',
        title: '一週不斷線',
        description: '連續學習 7 天',
        unlocked: streak >= 7,
      ),
      LearningBadge(
        id: 'tasks-50',
        title: '50 題突破',
        description: '累積完成 50 題',
        unlocked: report.totalTasks >= 50,
      ),
      LearningBadge(
        id: 'tasks-100',
        title: '百題里程碑',
        description: '累積完成 100 題',
        unlocked: report.totalTasks >= 100,
      ),
      LearningBadge(
        id: 'accuracy-80',
        title: '穩定命中',
        description: '至少 10 題且總答對率達 80%',
        unlocked: report.totalTasks >= 10 && report.overallAccuracy >= 80,
      ),
      LearningBadge(
        id: 'clear-mistakes',
        title: '清空錯題',
        description: '有訓練紀錄且目前沒有待加強錯題',
        unlocked: report.totalTasks > 0 && report.activeMistakeCount == 0,
      ),
    ];

    final byDate = <String, DailyTrainingSummary>{
      for (final item in latest) item.dateKey: item,
    };
    final calendar = <LearningCalendarDay>[];
    for (var offset = 27; offset >= 0; offset--) {
      final date = today.subtract(Duration(days: offset));
      final summary = byDate[DailyTrainingSummary.keyFor(date)];
      calendar.add(
        LearningCalendarDay(
          date: date,
          tasks: summary?.totalTasks ?? 0,
          correct: summary?.correctTasks ?? 0,
        ),
      );
    }

    return LearningGrowthSnapshot(
      dailyGoal: safeGoal,
      todayTasks: todaySummary?.totalTasks ?? 0,
      xp: xp,
      level: level,
      xpIntoLevel: xpIntoLevel,
      streak: streak,
      weeklyDays: currentWeek.length,
      weeklyTasks: weeklyTasks,
      weeklyCorrect: weeklyCorrect,
      previousWeekTasks: previousWeekTasks,
      bestSkillLabel: bestSkillLabel,
      focusSkillLabel: report.abilityReport.priorityLabel,
      badges: List.unmodifiable(badges),
      calendar: List.unmodifiable(calendar),
    );
  }

  static DateTime? _dateFromKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'vocabulary':
        return '單字・片語';
      case 'grammar':
        return '文法';
      case 'weakness':
        return '弱點改寫';
      case 'review':
        return 'SRS 複習';
      default:
        return type;
    }
  }
}
