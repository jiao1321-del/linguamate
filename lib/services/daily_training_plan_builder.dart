import '../models/ai_coach_reply.dart';
import '../models/daily_training.dart';
import '../models/learning_item.dart';
import '../models/mistake_record.dart';
import '../models/weakness_record.dart';

class DailyTrainingPlanBuilder {
  const DailyTrainingPlanBuilder._();

  static DailyTrainingPlan build({
    required List<LearningItem> learningItems,
    required List<WeaknessRecord> weaknesses,
    required List<AiCoachReply> coachReplies,
    List<MistakeRecord> mistakes = const <MistakeRecord>[],
    DateTime? now,
  }) {
    final tasks = <DailyTrainingTask>[];
    final activeMistakes = mistakes.where((item) => item.isActive).take(3);

    for (final mistake in activeMistakes) {
      tasks.add(mistake.toTask());
    }
    final referenceTime = now ?? DateTime.now();

    final vocabulary = _recentVocabulary(coachReplies);
    final vocabularyMeanings = vocabulary
        .map((item) => item.chinese.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    for (var index = 0; index < vocabulary.length && tasks.length < 3; index++) {
      final item = vocabulary[index];
      final options = <String>[
        item.chinese,
        ...vocabularyMeanings.where((meaning) => meaning != item.chinese),
      ].take(3).toList(growable: false);

      if (options.length > 1) {
        final offset = index % options.length;
        final rotated = [
          ...options.skip(offset),
          ...options.take(offset),
        ];
        final correctIndex = rotated.indexOf(item.chinese);
        final taskId = 'vocab-${item.term.toLowerCase()}';
        if (tasks.any((task) => task.id == taskId)) continue;
        tasks.add(
          DailyTrainingTask(
            id: taskId,
            type: 'vocabulary',
            title: '單字・片語',
            prompt: item.term,
            answer: item.chinese,
            explanation: [
              if (item.example.isNotEmpty) item.example,
              if (item.exampleChinese.isNotEmpty) item.exampleChinese,
            ].join('\n'),
            options: rotated,
            correctIndex: correctIndex,
            learningItemId: _matchingLearningItemId(
              learningItems,
              item.term,
            ),
          ),
        );
      } else {
        final taskId = 'vocab-${item.term.toLowerCase()}';
        if (tasks.any((task) => task.id == taskId)) continue;
        tasks.add(
          DailyTrainingTask(
            id: taskId,
            type: 'vocabulary',
            title: '單字・片語',
            prompt: item.term,
            answer: item.chinese,
            explanation: [
              if (item.example.isNotEmpty) item.example,
              if (item.exampleChinese.isNotEmpty) item.exampleChinese,
            ].join('\n'),
            learningItemId: _matchingLearningItemId(
              learningItems,
              item.term,
            ),
          ),
        );
      }
    }

    final grammarItems = _recentGrammar(coachReplies);
    for (var index = 0;
        index < grammarItems.length && index < 2 && tasks.length < 10;
        index++) {
      final grammar = grammarItems[index];
      final taskId = 'grammar-${grammar.title.toLowerCase()}';
      if (tasks.any((task) => task.id == taskId)) continue;
      tasks.add(
        DailyTrainingTask(
          id: taskId,
          type: 'grammar',
          title: '文法加強 · ${grammar.title}',
          prompt: grammar.question,
          answer: grammar.choices[grammar.answerIndex],
          explanation:
              '${grammar.explanation}\n${grammar.answerExplanation}',
          options: grammar.choices,
          correctIndex: grammar.answerIndex,
        ),
      );
    }

    for (var index = 0;
        index < weaknesses.length && index < 2 && tasks.length < 10;
        index++) {
      final weakness = weaknesses[index];
      final prompt = weakness.example.trim();
      final correction = weakness.correction.trim();
      if (prompt.isEmpty || correction.isEmpty) continue;

      final taskId = 'weakness-${weakness.category}-$index';
      if (tasks.any((task) => task.id == taskId)) continue;
      tasks.add(
        DailyTrainingTask(
          id: taskId,
          type: 'weakness',
          title: '弱點加強 · ${weakness.category}',
          prompt: prompt,
          answer: correction,
          explanation: weakness.explanation,
        ),
      );
    }

    final dueItems = learningItems
        .where(
          (item) =>
              item.isDue(referenceTime) &&
              item.analysis?.chinese.trim().isNotEmpty == true,
        )
        .take(3);

    for (final item in dueItems) {
      if (tasks.length >= 10) break;
      final taskId = 'review-${item.id}';
      if (tasks.any((task) => task.id == taskId)) continue;
      tasks.add(
        DailyTrainingTask(
          id: taskId,
          type: 'review',
          title: 'SRS 複習',
          prompt: item.text,
          answer: item.analysis!.chinese,
          explanation: item.analysis!.tone,
          learningItemId: item.id,
        ),
      );
    }

    return DailyTrainingPlan(
      tasks: tasks.take(10).toList(growable: false),
    );
  }

  static DailyTrainingPlan buildMistakeOnly(
    List<MistakeRecord> mistakes,
  ) {
    final tasks = mistakes
        .where((item) => item.isActive)
        .take(10)
        .map((item) => item.toTask())
        .toList(growable: false);
    return DailyTrainingPlan(tasks: tasks);
  }

  static List<AiCoachVocabulary> _recentVocabulary(
    List<AiCoachReply> replies,
  ) {
    final seen = <String>{};
    final result = <AiCoachVocabulary>[];

    for (final reply in replies.reversed) {
      for (final item in reply.vocabulary) {
        final key = item.term.trim().toLowerCase();
        if (key.isEmpty || !seen.add(key)) continue;
        result.add(item);
        if (result.length >= 3) return result;
      }
    }

    return result;
  }

  static List<AiCoachGrammar> _recentGrammar(
    List<AiCoachReply> replies,
  ) {
    final seen = <String>{};
    final result = <AiCoachGrammar>[];

    for (final reply in replies.reversed) {
      final grammar = reply.grammar;
      if (grammar == null || !grammar.isValid) continue;
      final key = grammar.title.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) continue;
      result.add(grammar);
      if (result.length >= 2) return result;
    }

    return result;
  }

  static String? _matchingLearningItemId(
    List<LearningItem> items,
    String text,
  ) {
    final normalized = text.trim().toLowerCase();
    for (final item in items) {
      if (item.text.trim().toLowerCase() == normalized) {
        return item.id;
      }
    }
    return null;
  }
}
