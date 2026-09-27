class DailyTrainingTask {
  final String id;
  final String type;
  final String title;
  final String prompt;
  final String answer;
  final String explanation;
  final List<String> options;
  final int? correctIndex;
  final String? learningItemId;

  const DailyTrainingTask({
    required this.id,
    required this.type,
    required this.title,
    required this.prompt,
    required this.answer,
    this.explanation = '',
    this.options = const <String>[],
    this.correctIndex,
    this.learningItemId,
  });

  bool get isMultipleChoice =>
      options.length >= 2 &&
      correctIndex != null &&
      correctIndex! >= 0 &&
      correctIndex! < options.length;
}

class DailyTrainingPlan {
  final List<DailyTrainingTask> tasks;

  const DailyTrainingPlan({
    required this.tasks,
  });

  int get totalTasks => tasks.length;

  int get estimatedMinutes {
    if (tasks.isEmpty) return 0;
    final minutes = (tasks.length * 0.75).ceil();
    return minutes.clamp(3, 10);
  }

  int countType(String type) =>
      tasks.where((task) => task.type == type).length;
}

class DailyTrainingSummary {
  final String dateKey;
  final int totalTasks;
  final int correctTasks;
  final DateTime completedAt;

  const DailyTrainingSummary({
    required this.dateKey,
    required this.totalTasks,
    required this.correctTasks,
    required this.completedAt,
  });

  bool isForDate(DateTime date) => dateKey == keyFor(date);

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'totalTasks': totalTasks,
        'correctTasks': correctTasks,
        'completedAt': completedAt.toIso8601String(),
      };

  factory DailyTrainingSummary.fromJson(Map<String, dynamic> json) {
    return DailyTrainingSummary(
      dateKey: (json['dateKey'] as String? ?? '').trim(),
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      correctTasks: (json['correctTasks'] as num?)?.toInt() ?? 0,
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static String keyFor(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
