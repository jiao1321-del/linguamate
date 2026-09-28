import 'gamification.dart';
import 'learner_memory_profile.dart';
import 'learning_insights.dart';

class NextBestAction {
  final String action;
  final String title;
  final String reason;
  final int estimatedMinutes;

  const NextBestAction({
    required this.action,
    required this.title,
    required this.reason,
    required this.estimatedMinutes,
  });
}

class IntelligenceCoreSnapshot {
  final NextBestAction nextBestAction;
  final LearnerMemoryProfile memory;
  final LearningInsightsSnapshot insights;
  final GamificationSnapshot gamification;
  final int adaptiveDifficulty;
  final int dueReviewCount;
  final int activeMistakeCount;
  final int roadmapProgress;
  final int campaignProgress;
  final int courseProgress;

  const IntelligenceCoreSnapshot({
    required this.nextBestAction,
    required this.memory,
    required this.insights,
    required this.gamification,
    required this.adaptiveDifficulty,
    required this.dueReviewCount,
    required this.activeMistakeCount,
    required this.roadmapProgress,
    required this.campaignProgress,
    required this.courseProgress,
  });

  String get coachMessage =>
      '${nextBestAction.title}：${nextBestAction.reason}';
}
