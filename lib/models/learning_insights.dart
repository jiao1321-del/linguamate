class LearningInsightsSnapshot {
  final int tasks7;
  final int tasks30;
  final int days7;
  final int days30;
  final int accuracy7;
  final int accuracy30;
  final int estimatedMinutes30;
  final int speakingAverage;
  final String fastestImproving;
  final String staleAbility;
  final String topMistake;
  final String weeklyReport;
  final List<String> nextActions;

  const LearningInsightsSnapshot({
    required this.tasks7,
    required this.tasks30,
    required this.days7,
    required this.days30,
    required this.accuracy7,
    required this.accuracy30,
    required this.estimatedMinutes30,
    required this.speakingAverage,
    required this.fastestImproving,
    required this.staleAbility,
    required this.topMistake,
    required this.weeklyReport,
    required this.nextActions,
  });
}
