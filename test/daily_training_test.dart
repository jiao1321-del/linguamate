import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguamate/models/ai_coach_reply.dart';
import 'package:linguamate/models/daily_training.dart';
import 'package:linguamate/models/language_analysis.dart';
import 'package:linguamate/models/learning_item.dart';
import 'package:linguamate/models/weakness_record.dart';
import 'package:linguamate/screens/daily_training_screen.dart';
import 'package:linguamate/screens/home_screen.dart';
import 'package:linguamate/services/daily_training_plan_builder.dart';
import 'package:linguamate/services/daily_training_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('DailyTrainingPlanBuilder mixes vocabulary grammar weakness and SRS', () {
    final now = DateTime.utc(2026, 9, 27, 3);
    final learningItem = LearningItem(
      id: 'saved-1',
      text: 'I need help.',
      createdAt: now,
      analysis: const LanguageAnalysis(
        detectedLanguage: 'English',
        chinese: '我需要幫忙。',
        english: 'I need help.',
        tagalog: 'Kailangan ko ng tulong.',
        tone: '自然。',
        learningPoints: [],
      ),
    );

    const reply = AiCoachReply(
      reply: 'Let’s check it together.',
      correction: '',
      explanation: '自然承接。',
      translation: '我們一起確認。',
      vocabulary: [
        AiCoachVocabulary(
          term: 'inspect',
          chinese: '檢查',
          example: 'Please inspect the machine.',
          exampleChinese: '請檢查機台。',
        ),
        AiCoachVocabulary(
          term: 'issue',
          chinese: '問題',
          example: 'There is an issue.',
          exampleChinese: '有一個問題。',
        ),
        AiCoachVocabulary(
          term: 'confirm',
          chinese: '確認',
          example: 'Please confirm the result.',
          exampleChinese: '請確認結果。',
        ),
      ],
      grammar: AiCoachGrammar(
        title: 'need to + 動詞',
        explanation: '表示需要做某件事。',
        question: 'We need to ___ the machine.',
        choices: ['inspect', 'inspected', 'inspecting'],
        answerIndex: 0,
        answerExplanation: 'need to 後面接原形動詞。',
      ),
    );

    final plan = DailyTrainingPlanBuilder.build(
      learningItems: [learningItem],
      weaknesses: [
        WeaknessRecord(
          category: '時態',
          count: 3,
          example: 'Yesterday I check it.',
          correction: 'Yesterday I checked it.',
          explanation: 'Yesterday 通常搭配過去式。',
          lastSeenAt: now,
        ),
      ],
      coachReplies: const [reply],
      now: now,
    );

    expect(plan.totalTasks, 6);
    expect(plan.countType('vocabulary'), 3);
    expect(plan.countType('grammar'), 1);
    expect(plan.countType('weakness'), 1);
    expect(plan.countType('review'), 1);
    expect(plan.tasks.first.options, hasLength(3));
    expect(plan.estimatedMinutes, 5);
  });

  testWidgets('DailyTrainingScreen records answers and completes session',
      (tester) async {
    final reviewCalls = <String>[];
    DailyTrainingSummary? completed;

    const plan = DailyTrainingPlan(
      tasks: [
        DailyTrainingTask(
          id: 'grammar-1',
          type: 'grammar',
          title: '文法加強',
          prompt: 'I ___ to work yesterday.',
          answer: 'went',
          explanation: 'yesterday 要用過去式。',
          options: ['go', 'went', 'going'],
          correctIndex: 1,
        ),
        DailyTrainingTask(
          id: 'review-1',
          type: 'review',
          title: 'SRS 複習',
          prompt: 'I need help.',
          answer: '我需要幫忙。',
          learningItemId: 'saved-1',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DailyTrainingScreen(
          plan: plan,
          onReviewResult: (id, remembered) async {
            reviewCalls.add('$id:$remembered');
          },
          onCompleted: (summary) async {
            completed = summary;
          },
        ),
      ),
    );

    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('daily-choice-1')));
    await tester.pumpAndSettle();
    expect(find.text('✅ 答對了'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('daily-next-task')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reveal-daily-answer')));
    await tester.pumpAndSettle();
    expect(find.text('我需要幫忙。'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('daily-remembered')));
    await tester.pumpAndSettle();

    expect(reviewCalls, ['saved-1:true']);
    expect(completed?.totalTasks, 2);
    expect(completed?.correctTasks, 2);
    expect(find.text('今日訓練完成 🎉'), findsOneWidget);
    expect(find.text('2 / 2 題完成'), findsOneWidget);
  });

  testWidgets('HomeScreen shows daily personalized training entry',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            items: const [],
            isLoading: false,
            dailyTrainingTaskCount: 6,
            dailyTrainingEstimatedMinutes: 5,
            dailyTrainingCompleted: false,
            onStartDailyTraining: () {},
            onStartReview: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('daily-training-card')), findsOneWidget);
    expect(find.text('今日訓練'), findsOneWidget);
    expect(find.text('6 題 · 約 5 分鐘'), findsOneWidget);
    expect(find.text('開始今日訓練'), findsOneWidget);
  });

  test('DailyTrainingStore persists completion summary', () async {
    const store = DailyTrainingStore();
    final summary = DailyTrainingSummary(
      dateKey: '2026-09-27',
      totalTasks: 8,
      correctTasks: 6,
      completedAt: DateTime.utc(2026, 9, 27, 3),
    );

    await store.save(summary);
    final loaded = await store.load();

    expect(loaded?.dateKey, '2026-09-27');
    expect(loaded?.totalTasks, 8);
    expect(loaded?.correctTasks, 6);
    expect(loaded?.isForDate(DateTime(2026, 9, 27)), isTrue);
  });
}
