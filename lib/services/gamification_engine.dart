import '../models/daily_training.dart';
import '../models/gamification.dart';
import '../models/learning_progress.dart';
import '../models/speaking_attempt.dart';

class GamificationEngine {
  const GamificationEngine._();

  static GamificationSnapshot build({
    required LearningProgressReport progress,
    required List<SpeakingAttempt> speaking,
    required int dailyGoal,
    required Set<String> courseCompleted,
    required Set<String> campaignCompleted,
    required Set<String> roadmapCompleted,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final todayKey = DailyTrainingSummary.keyFor(reference);
    DailyTrainingSummary? today;
    for (final item in progress.latestPerDay) {
      if (item.dateKey == todayKey) {
        today = item;
        break;
      }
    }

    final start7 = DateTime(reference.year, reference.month, reference.day)
        .subtract(const Duration(days: 6));
    final weeklyDays = progress.latestPerDay
        .where((item) => !item.completedAt.toLocal().isBefore(start7))
        .length;
    final speakingToday = speaking.where((item) {
      final date = item.recordedAt.toLocal();
      return DailyTrainingSummary.keyFor(date) == todayKey;
    }).length;
    final speakingWeek = speaking
        .where((item) => !item.recordedAt.toLocal().isBefore(start7))
        .length;

    final xp = progress.totalTasks * 2 +
        progress.totalCorrect * 8 +
        progress.completedDays * 12 +
        speaking.length * 20 +
        courseCompleted.length * 100 +
        campaignCompleted.length * 120 +
        roadmapCompleted.length * 10;

    const xpPerLevel = 300;
    final level = xp ~/ xpPerLevel + 1;
    final title = _title(level);

    return GamificationSnapshot(
      xp: xp,
      level: level,
      xpIntoLevel: xp % xpPerLevel,
      xpPerLevel: xpPerLevel,
      title: title,
      streak: progress.streakAt(reference),
      dailyQuests: <LearningQuest>[
        LearningQuest(
          id: 'daily-questions',
          title: '完成今日題目',
          progress: today?.totalTasks ?? 0,
          target: dailyGoal,
          reward: '+40 XP',
        ),
        LearningQuest(
          id: 'daily-speaking',
          title: '完成 1 次口說',
          progress: speakingToday,
          target: 1,
          reward: '+20 XP',
        ),
        LearningQuest(
          id: 'daily-accuracy',
          title: '今日答對 8 題',
          progress: today?.correctTasks ?? 0,
          target: 8,
          reward: '+30 XP',
        ),
      ],
      weeklyQuests: <LearningQuest>[
        LearningQuest(
          id: 'weekly-days',
          title: '本週學習 5 天',
          progress: weeklyDays,
          target: 5,
          reward: '+100 XP',
        ),
        LearningQuest(
          id: 'weekly-questions',
          title: '本週完成 50 題',
          progress: progress.last7DaysTasks(reference),
          target: 50,
          reward: '+120 XP',
        ),
        LearningQuest(
          id: 'weekly-speaking',
          title: '本週口說 3 次',
          progress: speakingWeek,
          target: 3,
          reward: '+80 XP',
        ),
      ],
    );
  }

  static String _title(int level) {
    if (level >= 30) return 'Natural Communicator';
    if (level >= 20) return 'Confident Speaker';
    if (level >= 15) return 'Workplace Speaker';
    if (level >= 8) return 'Conversation Rookie';
    if (level >= 4) return 'Daily Explorer';
    return 'Language Starter';
  }
}
