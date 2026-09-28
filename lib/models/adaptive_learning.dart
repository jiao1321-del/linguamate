import 'learning_item.dart';

enum SpeakingTokenStatus {
  correct,
  missing,
  extra,
}

class SpeakingTokenFeedback {
  final String word;
  final SpeakingTokenStatus status;

  const SpeakingTokenFeedback({
    required this.word,
    required this.status,
  });
}

class AdaptiveReviewDecision {
  final LearningItem item;
  final int intervalDays;
  final String reason;

  const AdaptiveReviewDecision({
    required this.item,
    required this.intervalDays,
    required this.reason,
  });
}

class PronunciationAssessment {
  final String target;
  final String transcript;
  final int completeness;
  final int fluency;
  final int score;
  final List<String> missingWords;
  final String naturalSuggestion;
  final List<SpeakingTokenFeedback> wordFeedback;

  const PronunciationAssessment({
    required this.target,
    required this.transcript,
    required this.completeness,
    required this.fluency,
    required this.score,
    required this.missingWords,
    required this.naturalSuggestion,
    this.wordFeedback = const <SpeakingTokenFeedback>[],
  });

  bool get passed => score >= 75;

  String get missingWordsLabel =>
      missingWords.isEmpty ? '沒有明顯漏字' : '漏字：${missingWords.join('、')}';
}

class AdaptiveCourseDay {
  final int day;
  final String title;
  final String focus;
  final String reason;
  final String action;

  const AdaptiveCourseDay({
    required this.day,
    required this.title,
    required this.focus,
    required this.reason,
    required this.action,
  });
}

class LearnerMemorySummary {
  final String summary;
  final List<String> masteredSkills;
  final String? prioritySkill;
  final int savedItemCount;
  final int activeMistakeCount;

  const LearnerMemorySummary({
    required this.summary,
    required this.masteredSkills,
    required this.prioritySkill,
    required this.savedItemCount,
    required this.activeMistakeCount,
  });
}

class AdaptiveLearningSnapshot {
  final String stage;
  final int difficulty;
  final String coachMessage;
  final String dailyPlanReason;
  final String smartReviewReason;
  final String recommendedAction;
  final LearnerMemorySummary memory;
  final List<AdaptiveCourseDay> course;
  final int dueReviewCount;
  final int activeMistakeCount;
  final int speakingAttempts;
  final int speakingAccuracy;

  const AdaptiveLearningSnapshot({
    required this.stage,
    required this.difficulty,
    required this.coachMessage,
    required this.dailyPlanReason,
    required this.smartReviewReason,
    required this.recommendedAction,
    required this.memory,
    required this.course,
    required this.dueReviewCount,
    required this.activeMistakeCount,
    required this.speakingAttempts,
    required this.speakingAccuracy,
  });

  String get difficultyLabel => switch (difficulty) {
        <= 1 => '基礎',
        2 => '初階',
        3 => '中階',
        4 => '中高階',
        _ => '進階',
      };
}
