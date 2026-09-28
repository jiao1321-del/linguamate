class LearningQuest {
  final String id;
  final String title;
  final int progress;
  final int target;
  final String reward;

  const LearningQuest({
    required this.id,
    required this.title,
    required this.progress,
    required this.target,
    required this.reward,
  });

  bool get completed => progress >= target;

  double get ratio =>
      target <= 0 ? 1 : (progress / target).clamp(0, 1).toDouble();
}

class GamificationSnapshot {
  final int xp;
  final int level;
  final int xpIntoLevel;
  final int xpPerLevel;
  final String title;
  final int streak;
  final List<LearningQuest> dailyQuests;
  final List<LearningQuest> weeklyQuests;

  const GamificationSnapshot({
    required this.xp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpPerLevel,
    required this.title,
    required this.streak,
    required this.dailyQuests,
    required this.weeklyQuests,
  });

  double get levelProgress =>
      (xpIntoLevel / xpPerLevel).clamp(0, 1).toDouble();
}
