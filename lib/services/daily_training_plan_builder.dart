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
    String? priorityType,
    DateTime? now,
  }) {
    final tasks = <DailyTrainingTask>[];
    final activeMistakes = mistakes.where((item) => item.isActive).take(3);

    for (final mistake in activeMistakes) {
      _addUnique(tasks, mistake.toTask());
    }

    final referenceTime = now ?? DateTime.now();
    final candidates = <DailyTrainingTask>[];

    final vocabulary = _recentVocabulary(coachReplies);
    final vocabularyMeanings = vocabulary
        .map((item) => item.chinese.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    for (var index = 0; index < vocabulary.length && index < 3; index++) {
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
        _addUnique(
          candidates,
          DailyTrainingTask(
            id: 'vocab-${item.term.toLowerCase()}',
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
        _addUnique(
          candidates,
          DailyTrainingTask(
            id: 'vocab-${item.term.toLowerCase()}',
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
    for (var index = 0; index < grammarItems.length && index < 2; index++) {
      final grammar = grammarItems[index];
      _addUnique(
        candidates,
        DailyTrainingTask(
          id: 'grammar-${grammar.title.toLowerCase()}',
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

    for (var index = 0; index < weaknesses.length && index < 2; index++) {
      final weakness = weaknesses[index];
      final prompt = weakness.example.trim();
      final correction = weakness.correction.trim();
      if (prompt.isEmpty || correction.isEmpty) continue;

      _addUnique(
        candidates,
        DailyTrainingTask(
          id: 'weakness-${weakness.category}-$index',
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
      _addUnique(
        candidates,
        DailyTrainingTask(
          id: 'review-${item.id}',
          type: 'review',
          title: 'SRS 複習',
          prompt: item.text,
          answer: item.analysis!.chinese,
          explanation: item.analysis!.tone,
          learningItemId: item.id,
        ),
      );
    }

    if (priorityType != null && priorityType.trim().isNotEmpty) {
      candidates.sort((a, b) {
        final aPriority = a.type == priorityType ? 0 : 1;
        final bPriority = b.type == priorityType ? 0 : 1;
        return aPriority.compareTo(bPriority);
      });
    }

    for (final candidate in candidates) {
      if (tasks.length >= 10) break;
      _addUnique(tasks, candidate);
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

  static void _addUnique(
    List<DailyTrainingTask> tasks,
    DailyTrainingTask task,
  ) {
    if (tasks.any((item) => item.id == task.id)) return;
    tasks.add(task);
  }
}
