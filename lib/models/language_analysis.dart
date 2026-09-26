class LearningPoint {
  final String title;
  final String explanation;

  const LearningPoint({
    required this.title,
    required this.explanation,
  });

  factory LearningPoint.fromJson(Map<String, dynamic> json) {
    return LearningPoint(
      title: (json['title'] as String? ?? '').trim(),
      explanation: (json['explanation'] as String? ?? '').trim(),
    );
  }
}

class LanguageAnalysis {
  final String detectedLanguage;
  final String chinese;
  final String english;
  final String tagalog;
  final String tone;
  final List<LearningPoint> learningPoints;

  const LanguageAnalysis({
    required this.detectedLanguage,
    required this.chinese,
    required this.english,
    required this.tagalog,
    required this.tone,
    required this.learningPoints,
  });

  factory LanguageAnalysis.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['learningPoints'];

    return LanguageAnalysis(
      detectedLanguage:
          (json['detectedLanguage'] as String? ?? 'Other').trim(),
      chinese: (json['chinese'] as String? ?? '').trim(),
      english: (json['english'] as String? ?? '').trim(),
      tagalog: (json['tagalog'] as String? ?? '').trim(),
      tone: (json['tone'] as String? ?? '').trim(),
      learningPoints: rawPoints is List
          ? rawPoints
              .whereType<Map>()
              .map(
                (item) => LearningPoint.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .where(
                (item) =>
                    item.title.isNotEmpty || item.explanation.isNotEmpty,
              )
              .toList(growable: false)
          : const [],
    );
  }
}
