class LearningPathStep {
  final String id;
  final String title;
  final String reason;
  final String action;
  final String actionLabel;

  const LearningPathStep({
    required this.id,
    required this.title,
    required this.reason,
    required this.action,
    required this.actionLabel,
  });
}

class LearningPathPlan {
  final List<LearningPathStep> steps;

  const LearningPathPlan({
    required this.steps,
  });

  bool get isEmpty => steps.isEmpty;
}
