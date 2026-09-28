class LearnerMemoryProfile {
  final DateTime updatedAt;
  final List<String> masteredSkills;
  final List<String> weakSkills;
  final List<String> staleSkills;
  final List<String> commonMistakes;
  final List<String> speakingWeakWords;
  final String preferredScenario;
  final String summary;

  const LearnerMemoryProfile({
    required this.updatedAt,
    required this.masteredSkills,
    required this.weakSkills,
    required this.staleSkills,
    required this.commonMistakes,
    required this.speakingWeakWords,
    required this.preferredScenario,
    required this.summary,
  });

  const LearnerMemoryProfile.empty()
      : updatedAt = const DateTime.fromMillisecondsSinceEpoch(0),
        masteredSkills = const <String>[],
        weakSkills = const <String>[],
        staleSkills = const <String>[],
        commonMistakes = const <String>[],
        speakingWeakWords = const <String>[],
        preferredScenario = '自由對話',
        summary = '';

  Map<String, dynamic> toJson() => {
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'masteredSkills': masteredSkills,
        'weakSkills': weakSkills,
        'staleSkills': staleSkills,
        'commonMistakes': commonMistakes,
        'speakingWeakWords': speakingWeakWords,
        'preferredScenario': preferredScenario,
        'summary': summary,
      };

  factory LearnerMemoryProfile.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) {
      final raw = json[key];
      return raw is List
          ? raw.whereType<String>().toList(growable: false)
          : const <String>[];
    }

    return LearnerMemoryProfile(
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      masteredSkills: strings('masteredSkills'),
      weakSkills: strings('weakSkills'),
      staleSkills: strings('staleSkills'),
      commonMistakes: strings('commonMistakes'),
      speakingWeakWords: strings('speakingWeakWords'),
      preferredScenario:
          (json['preferredScenario'] as String? ?? '自由對話').trim(),
      summary: (json['summary'] as String? ?? '').trim(),
    );
  }
}
