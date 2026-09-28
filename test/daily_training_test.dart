import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguamate/models/ai_coach_reply.dart';
import 'package:linguamate/models/daily_training.dart';
import 'package:linguamate/models/language_analysis.dart';
import 'package:linguamate/models/learning_item.dart';
import 'package:linguamate/models/learning_ability.dart';
import 'package:linguamate/models/learning_path.dart';
import 'package:linguamate/models/learning_progress.dart';
import 'package:linguamate/models/mistake_record.dart';
import 'package:linguamate/models/weakness_record.dart';
import 'package:linguamate/screens/daily_training_screen.dart';
import 'package:linguamate/screens/home_screen.dart';
import 'package:linguamate/screens/profile_screen.dart';
import 'package:linguamate/screens/progress_center_screen.dart';
import 'package:linguamate/services/daily_training_plan_builder.dart';
import 'package:linguamate/services/daily_training_store.dart';
import 'package:linguamate/services/learning_ability_analyzer.dart';
import 'package:linguamate/services/learning_ability_store.dart';
import 'package:linguamate/services/learning_path_planner.dart';
import 'package:linguamate/services/learning_progress_store.dart';
import 'package:linguamate/services/mistake_store.dart';
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
    await tester.ensureVisible(
      find.byKey(const ValueKey('daily-choice-1')),
    );
    await tester.tap(find.byKey(const ValueKey('daily-choice-1')));
    await tester.pumpAndSettle();
    expect(find.text('✅ 答對了'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('daily-next-task')),
    );
    await tester.tap(find.byKey(const ValueKey('daily-next-task')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('reveal-daily-answer')),
    );
    await tester.tap(find.byKey(const ValueKey('reveal-daily-answer')));
    await tester.pumpAndSettle();
    expect(find.text('我需要幫忙。'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('daily-remembered')),
    );
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
            dailyTrainingFocusLabel: '過去式',
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
    expect(
      find.text('今日優先：過去式 · 依熟練度自動調整題目順序。'),
      findsOneWidget,
    );
  });

  test('MistakeStore records errors and fades after three correct answers',
      () async {
    const store = MistakeStore();
    const task = DailyTrainingTask(
      id: 'grammar-tense',
      type: 'grammar',
      title: '文法加強 · 過去式',
      prompt: 'Yesterday I ___ home.',
      answer: 'went',
      explanation: 'Yesterday 通常使用過去式。',
      options: ['go', 'went', 'going'],
      correctIndex: 1,
    );
    final start = DateTime.utc(2026, 9, 27, 4);

    var records = await store.recordResult(
      task: task,
      correct: false,
      now: start,
    );
    expect(records, hasLength(1));
    expect(records.first.wrongCount, 1);
    expect(records.first.correctStreak, 0);
    expect(records.first.isActive, isTrue);

    records = await store.recordResult(
      task: task,
      correct: false,
      now: start.add(const Duration(minutes: 1)),
    );
    expect(records.first.wrongCount, 2);

    for (var index = 0; index < 3; index++) {
      records = await store.recordResult(
        task: task,
        correct: true,
        now: start.add(Duration(minutes: index + 2)),
      );
    }

    expect(records.first.correctStreak, 3);
    expect(records.first.isActive, isFalse);
    expect(store.active(records), isEmpty);
  });

  test('DailyTrainingPlanBuilder puts active mistakes first', () {
    final now = DateTime.utc(2026, 9, 27, 4);
    final mistake = MistakeRecord(
      taskId: 'grammar-past',
      type: 'grammar',
      title: '文法加強 · 過去式',
      prompt: 'Yesterday I ___ home.',
      answer: 'went',
      explanation: 'Yesterday 通常使用過去式。',
      options: const ['go', 'went', 'going'],
      correctIndex: 1,
      wrongCount: 4,
      correctStreak: 0,
      lastWrongAt: now,
    );

    final plan = DailyTrainingPlanBuilder.build(
      learningItems: const [],
      weaknesses: const [],
      coachReplies: const [],
      mistakes: [mistake],
      now: now,
    );

    expect(plan.tasks, isNotEmpty);
    expect(plan.tasks.first.id, 'grammar-past');

    final mistakeOnly = DailyTrainingPlanBuilder.buildMistakeOnly([mistake]);
    expect(mistakeOnly.totalTasks, 1);
    expect(mistakeOnly.tasks.first.prompt, 'Yesterday I ___ home.');
  });

  testWidgets('ProfileScreen shows mistake book and retry action',
      (tester) async {
    var practiced = false;
    final mistake = MistakeRecord(
      taskId: 'vocab-issue',
      type: 'vocabulary',
      title: '單字・片語',
      prompt: 'issue',
      answer: '問題',
      explanation: 'There is an issue.',
      wrongCount: 2,
      correctStreak: 0,
      lastWrongAt: DateTime.utc(2026, 9, 27, 4),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          items: const [],
          isLoading: false,
          mistakes: [mistake],
          onPracticeMistakes: () => practiced = true,
          onOpenBackup: () {},
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mistake-book-card')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('錯題本'), findsOneWidget);
    expect(find.text('1 待加強'), findsOneWidget);
    expect(find.text('issue'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('practice-mistakes-button')));
    expect(practiced, isTrue);
  });

  test('LearningAbilityStore tracks mastery and weak skills', () async {
    const store = LearningAbilityStore();
    const vocabularyTask = DailyTrainingTask(
      id: 'vocab-inspect',
      type: 'vocabulary',
      title: '單字・片語',
      prompt: 'inspect',
      answer: '檢查',
    );
    const grammarTask = DailyTrainingTask(
      id: 'grammar-past',
      type: 'grammar',
      title: '文法加強 · 過去式',
      prompt: 'Yesterday I ___ home.',
      answer: 'went',
      options: ['go', 'went', 'going'],
      correctIndex: 1,
    );
    final start = DateTime.utc(2026, 9, 28, 1);

    var records = await store.recordResult(
      task: grammarTask,
      correct: false,
      now: start,
    );
    records = await store.recordResult(
      task: grammarTask,
      correct: false,
      now: start.add(const Duration(minutes: 1)),
    );

    var grammar = records.firstWhere((item) => item.type == 'grammar');
    expect(grammar.status, AbilityStatus.needsWork);
    expect(grammar.wrongCount, 2);
    expect(grammar.accuracy, 0);

    await store.recordResult(
      task: vocabularyTask,
      correct: false,
      now: start.add(const Duration(minutes: 2)),
    );
    for (var index = 0; index < 4; index++) {
      records = await store.recordResult(
        task: vocabularyTask,
        correct: true,
        now: start.add(Duration(minutes: index + 3)),
      );
    }

    final vocabulary =
        records.firstWhere((item) => item.type == 'vocabulary');
    expect(vocabulary.attempts, 5);
    expect(vocabulary.correctCount, 4);
    expect(vocabulary.score, greaterThanOrEqualTo(80));
    expect(vocabulary.status, AbilityStatus.mastered);

    grammar = records.firstWhere((item) => item.type == 'grammar');
    expect(grammar.statusLabel, '待加強');
  });

  test('LearningAbilityAnalyzer can seed report from existing weaknesses', () {
    final now = DateTime.utc(2026, 9, 28, 2);
    final report = LearningAbilityAnalyzer.build(
      tracked: const [],
      mistakes: const [],
      weaknesses: [
        WeaknessRecord(
          category: '時態',
          count: 3,
          example: 'Yesterday I go home.',
          correction: 'Yesterday I went home.',
          explanation: '過去時間用過去式。',
          lastSeenAt: now,
        ),
      ],
    );

    expect(report.records, hasLength(1));
    expect(report.priorityLabel, '時態');
    expect(report.priorityType, 'weakness');
    expect(report.needsWorkCount, 1);
    expect(report.totalWrong, 3);
  });

  test('DailyTrainingPlanBuilder moves weakest skill type forward', () {
    const reply = AiCoachReply(
      reply: 'Try this.',
      correction: '',
      explanation: '',
      translation: '',
      vocabulary: [
        AiCoachVocabulary(
          term: 'inspect',
          chinese: '檢查',
          example: 'Please inspect it.',
          exampleChinese: '請檢查它。',
        ),
        AiCoachVocabulary(
          term: 'confirm',
          chinese: '確認',
          example: 'Please confirm it.',
          exampleChinese: '請確認它。',
        ),
      ],
      grammar: AiCoachGrammar(
        title: '過去式',
        explanation: '過去發生的事情使用過去式。',
        question: 'Yesterday I ___ home.',
        choices: ['go', 'went', 'going'],
        answerIndex: 1,
        answerExplanation: 'Yesterday 對應 went。',
      ),
    );

    final plan = DailyTrainingPlanBuilder.build(
      learningItems: const [],
      weaknesses: const [],
      coachReplies: const [reply],
      priorityType: 'grammar',
    );

    expect(plan.tasks, isNotEmpty);
    expect(plan.tasks.first.type, 'grammar');
    expect(plan.tasks.first.title, contains('過去式'));
  });

  testWidgets('ProfileScreen shows learning ability dashboard',
      (tester) async {
    final now = DateTime.utc(2026, 9, 28, 3);
    final report = LearningAbilityReport(
      records: [
        LearningAbilityRecord(
          key: 'grammar:past',
          label: '過去式',
          type: 'grammar',
          attempts: 4,
          correctCount: 1,
          wrongCount: 3,
          correctStreak: 0,
          lastResultCorrect: false,
          lastPracticedAt: now,
        ),
        LearningAbilityRecord(
          key: 'vocabulary',
          label: '單字・片語',
          type: 'vocabulary',
          attempts: 5,
          correctCount: 4,
          wrongCount: 1,
          correctStreak: 4,
          lastResultCorrect: true,
          lastPracticedAt: now,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          items: const [],
          isLoading: false,
          abilityReport: report,
          onOpenBackup: () {},
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('learning-ability-card')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('學習能力'), findsOneWidget);
    expect(find.text('🎯 目前優先加強：過去式'), findsOneWidget);
    expect(find.text('過去式'), findsOneWidget);
    expect(find.text('待加強'), findsAtLeastNWidgets(1));
    expect(find.text('單字・片語'), findsOneWidget);
    expect(find.text('已掌握'), findsAtLeastNWidgets(1));
  });

  test('LearningProgressStore keeps training history and streak data',
      () async {
    const store = LearningProgressStore();
    final first = DailyTrainingSummary(
      dateKey: '2026-09-27',
      totalTasks: 8,
      correctTasks: 6,
      completedAt: DateTime(2026, 9, 27, 9),
      typeTotals: const {
        'vocabulary': 4,
        'grammar': 4,
      },
      typeCorrect: const {
        'vocabulary': 4,
        'grammar': 2,
      },
    );
    final second = DailyTrainingSummary(
      dateKey: '2026-09-28',
      totalTasks: 10,
      correctTasks: 8,
      completedAt: DateTime(2026, 9, 28, 9),
      typeTotals: const {
        'vocabulary': 5,
        'grammar': 5,
      },
      typeCorrect: const {
        'vocabulary': 4,
        'grammar': 4,
      },
    );

    await store.append(first);
    final history = await store.append(second);

    expect(history, hasLength(2));

    const abilityReport = LearningAbilityReport(
      records: <LearningAbilityRecord>[],
    );
    final report = LearningProgressReport(
      history: history,
      abilityReport: abilityReport,
      activeMistakeCount: 1,
    );

    expect(report.streakAt(DateTime(2026, 9, 28)), 2);
    expect(report.totalTasks, 18);
    expect(report.totalCorrect, 14);
    expect(report.typeAccuracy('vocabulary'), 89);
    expect(report.typeAccuracy('grammar'), 67);
  });

  testWidgets('ProgressCenterScreen shows progress metrics',
      (tester) async {
    final report = LearningProgressReport(
      history: [
        DailyTrainingSummary(
          dateKey: '2026-09-28',
          totalTasks: 10,
          correctTasks: 8,
          completedAt: DateTime.now(),
          typeTotals: const {
            'vocabulary': 5,
            'grammar': 5,
          },
          typeCorrect: const {
            'vocabulary': 4,
            'grammar': 4,
          },
        ),
      ],
      abilityReport: const LearningAbilityReport(
        records: <LearningAbilityRecord>[],
      ),
      activeMistakeCount: 2,
    );

    await tester.pumpWidget(
      MaterialApp(home: ProgressCenterScreen(report: report)),
    );
    await tester.pumpAndSettle();

    expect(find.text('學習進度中心'), findsOneWidget);
    expect(find.text('總答對率'), findsOneWidget);
    expect(find.text('80%'), findsAtLeastNWidgets(1));
    expect(find.byKey(const ValueKey('progress-skill-card')), findsOneWidget);
  });

  test('LearningPathPlanner creates three adaptive next steps', () {
    final now = DateTime.utc(2026, 9, 28, 4);
    final ability = LearningAbilityRecord(
      key: 'grammar:過去式',
      label: '過去式',
      type: 'grammar',
      attempts: 4,
      correctCount: 1,
      wrongCount: 3,
      correctStreak: 0,
      lastResultCorrect: false,
      lastPracticedAt: now,
    );
    final mistake = MistakeRecord(
      taskId: 'grammar-past',
      type: 'grammar',
      title: '文法加強 · 過去式',
      prompt: 'Yesterday I ___ home.',
      answer: 'went',
      explanation: 'Yesterday 通常使用過去式。',
      options: const ['go', 'went', 'going'],
      correctIndex: 1,
      wrongCount: 2,
      correctStreak: 0,
      lastWrongAt: now,
    );

    final abilityReport = LearningAbilityReport(records: [ability]);
    final progressReport = LearningProgressReport(
      history: const [],
      abilityReport: abilityReport,
      activeMistakeCount: 1,
    );

    final plan = LearningPathPlanner.build(
      abilityReport: abilityReport,
      progressReport: progressReport,
      mistakes: [mistake],
    );

    expect(plan.steps, hasLength(3));
    expect(plan.steps.first.title, '先補強 過去式');
    expect(plan.steps[1].action, 'mistakes');
    expect(plan.steps[2].action, 'roleplay');
  });

  testWidgets('HomeScreen renders personalized learning path',
      (tester) async {
    const plan = LearningPathPlan(
      steps: [
        LearningPathStep(
          id: 'focus',
          title: '先補強 過去式',
          reason: '目前這是最需要優先處理的能力。',
          action: 'daily',
          actionLabel: '開始今日訓練',
        ),
        LearningPathStep(
          id: 'roleplay',
          title: '完成 1 個 AI 情境任務',
          reason: '把能力放進真實情境。',
          action: 'roleplay',
          actionLabel: '進入情境任務',
        ),
      ],
    );
    String? action;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            items: const [],
            isLoading: false,
            learningStreak: 4,
            learningPath: plan,
            onLearningPathAction: (value) => action = value,
            onStartReview: () {},
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('learning-path-card')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('我的學習路線'), findsOneWidget);
    expect(find.text('先補強 過去式'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('learning-path-action-1')));
    expect(action, 'roleplay');
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
