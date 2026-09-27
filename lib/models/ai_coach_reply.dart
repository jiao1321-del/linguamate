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

class AiCoachVocabulary {
  final String term;
  final String chinese;
  final String example;
  final String exampleChinese;

  const AiCoachVocabulary({
    required this.term,
    required this.chinese,
    required this.example,
    required this.exampleChinese,
  });

  Map<String, dynamic> toJson() {
    return {
      'term': term,
      'chinese': chinese,
      'example': example,
      'exampleChinese': exampleChinese,
    };
  }

  factory AiCoachVocabulary.fromJson(Map<String, dynamic> json) {
    return AiCoachVocabulary(
      term: (json['term'] as String? ?? '').trim(),
      chinese: (json['chinese'] as String? ?? '').trim(),
      example: (json['example'] as String? ?? '').trim(),
      exampleChinese: (json['exampleChinese'] as String? ?? '').trim(),
    );
  }
}

class AiCoachGrammar {
  final String title;
  final String explanation;
  final String question;
  final List<String> choices;
  final int answerIndex;
  final String answerExplanation;

  const AiCoachGrammar({
    required this.title,
    required this.explanation,
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.answerExplanation,
  });

  bool get isValid =>
      title.trim().isNotEmpty &&
      explanation.trim().isNotEmpty &&
      question.trim().isNotEmpty &&
      choices.length >= 2 &&
      answerIndex >= 0 &&
      answerIndex < choices.length;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'explanation': explanation,
      'question': question,
      'choices': choices,
      'answerIndex': answerIndex,
      'answerExplanation': answerExplanation,
    };
  }

  factory AiCoachGrammar.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'];
    final choices = rawChoices is List
        ? rawChoices
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .take(4)
            .toList(growable: false)
        : const <String>[];

    return AiCoachGrammar(
      title: (json['title'] as String? ?? '').trim(),
      explanation: (json['explanation'] as String? ?? '').trim(),
      question: (json['question'] as String? ?? '').trim(),
      choices: choices,
      answerIndex: json['answerIndex'] as int? ?? -1,
      answerExplanation:
          (json['answerExplanation'] as String? ?? '').trim(),
    );
  }
}

class AiCoachReply {
  final String reply;
  final String correction;
  final String explanation;
  final String translation;
  final List<AiCoachSuggestion> suggestions;
  final List<AiCoachVocabulary> vocabulary;
  final AiCoachGrammar? grammar;

  const AiCoachReply({
    required this.reply,
    required this.correction,
    required this.explanation,
    required this.translation,
    this.suggestions = const <AiCoachSuggestion>[],
    this.vocabulary = const <AiCoachVocabulary>[],
    this.grammar,
  });

  bool get hasCorrection => correction.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'reply': reply,
      'correction': correction,
      'explanation': explanation,
      'translation': translation,
      'suggestions': suggestions.map((item) => item.toJson()).toList(),
      'vocabulary': vocabulary.map((item) => item.toJson()).toList(),
      'grammar': grammar?.toJson(),
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

    final rawVocabulary = json['vocabulary'];
    final vocabulary = rawVocabulary is List
        ? rawVocabulary
            .whereType<Map>()
            .map(
              (item) => AiCoachVocabulary.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where(
              (item) =>
                  item.term.isNotEmpty &&
                  item.chinese.isNotEmpty &&
                  item.example.isNotEmpty,
            )
            .take(3)
            .toList(growable: false)
        : const <AiCoachVocabulary>[];

    final rawGrammar = json['grammar'];
    final parsedGrammar = rawGrammar is Map
        ? AiCoachGrammar.fromJson(Map<String, dynamic>.from(rawGrammar))
        : null;

    return AiCoachReply(
      reply: (json['reply'] as String? ?? '').trim(),
      correction: (json['correction'] as String? ?? '').trim(),
      explanation: (json['explanation'] as String? ?? '').trim(),
      translation: (json['translation'] as String? ?? '').trim(),
      suggestions: suggestions,
      vocabulary: vocabulary,
      grammar: parsedGrammar?.isValid == true ? parsedGrammar : null,
    );
  }
}
