import 'daily_training.dart';

class MistakeRecord {
  final String taskId;
  final String type;
  final String title;
  final String prompt;
  final String answer;
  final String explanation;
  final List<String> options;
  final int? correctIndex;
  final String? learningItemId;
  final int wrongCount;
  final int correctStreak;
  final DateTime lastWrongAt;
  final DateTime? lastCorrectAt;

  const MistakeRecord({
    required this.taskId,
    required this.type,
    required this.title,
    required this.prompt,
    required this.answer,
    required this.explanation,
    this.options = const <String>[],
    this.correctIndex,
    this.learningItemId,
    required this.wrongCount,
    required this.correctStreak,
    required this.lastWrongAt,
    this.lastCorrectAt,
  });

  bool get isActive => correctStreak < 3;

  DailyTrainingTask toTask() {
    return DailyTrainingTask(
      id: taskId,
      type: type,
      title: title,
      prompt: prompt,
      answer: answer,
      explanation: explanation,
      options: options,
      correctIndex: correctIndex,
      learningItemId: learningItemId,
    );
  }

  MistakeRecord recordResult({
    required bool correct,
    required DateTime now,
  }) {
    if (correct) {
      return MistakeRecord(
        taskId: taskId,
        type: type,
        title: title,
        prompt: prompt,
        answer: answer,
        explanation: explanation,
        options: options,
        correctIndex: correctIndex,
        learningItemId: learningItemId,
        wrongCount: wrongCount,
        correctStreak: correctStreak + 1,
        lastWrongAt: lastWrongAt,
        lastCorrectAt: now,
      );
    }

    return MistakeRecord(
      taskId: taskId,
      type: type,
      title: title,
      prompt: prompt,
      answer: answer,
      explanation: explanation,
      options: options,
      correctIndex: correctIndex,
      learningItemId: learningItemId,
      wrongCount: wrongCount + 1,
      correctStreak: 0,
      lastWrongAt: now,
      lastCorrectAt: lastCorrectAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'type': type,
        'title': title,
        'prompt': prompt,
        'answer': answer,
        'explanation': explanation,
        'options': options,
        'correctIndex': correctIndex,
        'learningItemId': learningItemId,
        'wrongCount': wrongCount,
        'correctStreak': correctStreak,
        'lastWrongAt': lastWrongAt.toIso8601String(),
        'lastCorrectAt': lastCorrectAt?.toIso8601String(),
      };

  factory MistakeRecord.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions.whereType<String>().toList(growable: false)
        : const <String>[];

    return MistakeRecord(
      taskId: (json['taskId'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? 'review').trim(),
      title: (json['title'] as String? ?? '待加強').trim(),
      prompt: (json['prompt'] as String? ?? '').trim(),
      answer: (json['answer'] as String? ?? '').trim(),
      explanation: (json['explanation'] as String? ?? '').trim(),
      options: options,
      correctIndex: (json['correctIndex'] as num?)?.toInt(),
      learningItemId: json['learningItemId'] as String?,
      wrongCount: (json['wrongCount'] as num?)?.toInt() ?? 1,
      correctStreak: (json['correctStreak'] as num?)?.toInt() ?? 0,
      lastWrongAt:
          DateTime.tryParse(json['lastWrongAt'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      lastCorrectAt:
          DateTime.tryParse(json['lastCorrectAt'] as String? ?? ''),
    );
  }

  factory MistakeRecord.fromTask(
    DailyTrainingTask task, {
    required DateTime now,
  }) {
    return MistakeRecord(
      taskId: task.id,
      type: task.type,
      title: task.title,
      prompt: task.prompt,
      answer: task.answer,
      explanation: task.explanation,
      options: task.options,
      correctIndex: task.correctIndex,
      learningItemId: task.learningItemId,
      wrongCount: 1,
      correctStreak: 0,
      lastWrongAt: now,
    );
  }
}
