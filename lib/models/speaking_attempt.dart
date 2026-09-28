class SpeakingAttempt {
  final String id;
  final DateTime recordedAt;
  final String target;
  final String transcript;
  final int completeness;
  final int fluency;
  final int score;
  final List<String> missingWords;

  const SpeakingAttempt({
    required this.id,
    required this.recordedAt,
    required this.target,
    required this.transcript,
    required this.completeness,
    required this.fluency,
    required this.score,
    this.missingWords = const <String>[],
  });

  bool get passed => score >= 75;

  Map<String, dynamic> toJson() => {
        'id': id,
        'recordedAt': recordedAt.toIso8601String(),
        'target': target,
        'transcript': transcript,
        'completeness': completeness,
        'fluency': fluency,
        'score': score,
        'missingWords': missingWords,
      };

  factory SpeakingAttempt.fromJson(Map<String, dynamic> json) {
    final rawMissing = json['missingWords'];
    return SpeakingAttempt(
      id: (json['id'] as String? ?? '').trim(),
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      target: (json['target'] as String? ?? '').trim(),
      transcript: (json['transcript'] as String? ?? '').trim(),
      completeness: (json['completeness'] as num?)?.toInt() ?? 0,
      fluency: (json['fluency'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      missingWords: rawMissing is List
          ? rawMissing.whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }
}
