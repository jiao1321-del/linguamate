class AiCoachSuggestion {
  final String text;
  final String chinese;

  const AiCoachSuggestion({
    required this.text,
    required this.chinese,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'chinese': chinese,
    };
  }

  factory AiCoachSuggestion.fromJson(Map<String, dynamic> json) {
    return AiCoachSuggestion(
      text: (json['text'] as String? ?? '').trim(),
      chinese: (json['chinese'] as String? ?? '').trim(),
    );
  }
}

class AiCoachReply {
  final String reply;
  final String correction;
  final String explanation;
  final String translation;
  final List<AiCoachSuggestion> suggestions;

  const AiCoachReply({
    required this.reply,
    required this.correction,
    required this.explanation,
    required this.translation,
    this.suggestions = const <AiCoachSuggestion>[],
  });

  bool get hasCorrection => correction.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'reply': reply,
      'correction': correction,
      'explanation': explanation,
      'translation': translation,
      'suggestions': suggestions.map((item) => item.toJson()).toList(),
    };
  }

  factory AiCoachReply.fromJson(Map<String, dynamic> json) {
    final rawSuggestions = json['suggestions'];
    final suggestions = rawSuggestions is List
        ? rawSuggestions
            .whereType<Map>()
            .map(
              (item) => AiCoachSuggestion.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where(
              (item) => item.text.isNotEmpty && item.chinese.isNotEmpty,
            )
            .take(3)
            .toList(growable: false)
        : const <AiCoachSuggestion>[];

    return AiCoachReply(
      reply: (json['reply'] as String? ?? '').trim(),
      correction: (json['correction'] as String? ?? '').trim(),
      explanation: (json['explanation'] as String? ?? '').trim(),
      translation: (json['translation'] as String? ?? '').trim(),
      suggestions: suggestions,
    );
  }
}
