class TrainingTelemetry {
  final String id;
  final String taskId;
  final String type;
  final bool correct;
  final int responseMs;
  final bool usedHint;
  final DateTime recordedAt;

  const TrainingTelemetry({
    required this.id,
    required this.taskId,
    required this.type,
    required this.correct,
    required this.responseMs,
    required this.usedHint,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'type': type,
        'correct': correct,
        'responseMs': responseMs,
        'usedHint': usedHint,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      };

  factory TrainingTelemetry.fromJson(Map<String, dynamic> json) {
    return TrainingTelemetry(
      id: (json['id'] as String? ?? '').trim(),
      taskId: (json['taskId'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? 'review').trim(),
      correct: json['correct'] == true,
      responseMs: (json['responseMs'] as num?)?.toInt() ?? 0,
      usedHint: json['usedHint'] == true,
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
