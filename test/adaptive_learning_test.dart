import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguamate/models/ai_coach_reply.dart';
import 'package:linguamate/models/daily_training.dart';
import 'package:linguamate/models/language_analysis.dart';
import 'package:linguamate/models/learning_ability.dart';
import 'package:linguamate/models/learning_item.dart';
import 'package:linguamate/models/learning_progress.dart';
import 'package:linguamate/models/mistake_record.dart';
import 'package:linguamate/models/weakness_record.dart';
import 'package:linguamate/screens/adaptive_learning_screen.dart';
import 'package:linguamate/screens/ai_chat_screen.dart';
import 'package:linguamate/screens/daily_training_screen.dart';
import 'package:linguamate/services/adaptive_learning_engine.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  LearningProgressReport progressReport({
    int correct = 18,
    int total = 20,
  }) {
    final history = [
      DailyTrainingSummary(
        dateKey: '2026-09-27',
        totalTasks: 10,
        correctTasks: correct ~/ 2,
        completedAt: DateTime(2026, 9, 27, 9),
        typeTotals: const {'vocabulary': 5, 'grammar': 5},
        typeCorrect: const {'vocabulary': 4, 'grammar': 4},
      ),
      DailyTrainingSummary(
        dateKey: '2026-09-28',
        totalTasks: 10,
        correctTasks: correct - (correct ~/ 2),
        completedAt: DateTime(2026, 9, 28, 9),
        typeTotals: const {'vocabulary': 5, 'grammar': 5},
        typeCorrect: const {'vocabulary': 5, 'grammar': 4},
      ),
    ];

    return LearningProgressReport(
      history: history,
      abilityReport: LearningAbilityReport(
        records: [
          LearningAbilityRecord(
            key: 'grammar:past',
            label: '過去式',
            type: 'grammar',
            attempts: total,
            correctCount: correct,
            wrongCount: total - correct,
            correctStreak: 3,
            lastResultCorrect: true,
            lastPracticedAt: DateTime(2026, 9, 28, 9),
          ),
        ],
      ),
      activeMistakeCount: 1,
    );
  }

  test('V1.25 smart review expands interval for stable performance', () {
    final item = LearningItem(
      id: 'card-1',
      text: 'I need help.',
      createdAt: DateTime(2026, 9, 1),
      reviewLevel: 2,
      reviewCount: 5,
      analysis: const LanguageAnalysis(
        detectedLanguage: 'English',
        chinese: '我需要幫忙。',
        english: 'I need help.',
        tagalog: 'Kailangan ko ng tulong.',
        tone: '自然',
        learningPoints: [],
      ),
    );

    final decision = AdaptiveLearningEngine.reviewItem(
      item: item,
      remembered: true,
      progressReport: progressReport(),
      now: DateTime(2026, 9, 28, 10),
    );

    expect(decision.item.reviewLevel, 3);
    expect(decision.intervalDays, greaterThan(4));
    expect(decision.reason, contains('拉長'));
    expect(decision.item.nextReviewAt, isNotNull);
  });

  test('V1.27 speaking score detects missing words and usable fluency', () {
    final result = AdaptiveLearningEngine.assessPronunciation(
      target: 'I need to check the machine',
      transcript: 'I need check the machine',
    );

    expect(result.score, greaterThanOrEqualTo(75));
    expect(result.completeness, greaterThanOrEqualTo(80));
    expect(result.missingWords, contains('to'));
    expect(result.passed, isTrue);
  });

  test('V1.28-V1.30 snapshot builds course, memory and adaptive state', () {
    final now = DateTime(2026, 9, 28, 10);
    final ability = LearningAbilityReport(
      records: [
        LearningAbilityRecord(
          key: 'grammar:past',
          label: '過去式',
          type: 'grammar',
          attempts: 8,
          correctCount: 3,
          wrongCount: 5,
          correctStreak: 0,
          lastResultCorrect: false,
          lastPracticedAt: now,
        ),
        LearningAbilityRecord(
          key: 'vocabulary',
          label: '單字・片語',
          type: 'vocabulary',
          attempts: 10,
          correctCount: 9,
          wrongCount: 1,
          correctStreak: 4,
          lastResultCorrect: true,
          lastPracticedAt: now,
        ),
      ],
    );
    final report = LearningProgressReport(
      history: [
        DailyTrainingSummary(
          dateKey: '2026-09-28',
          totalTasks: 10,
          correctTasks: 7,
          completedAt: now,
          typeTotals: const {'grammar': 5, 'vocabulary': 5},
          typeCorrect: const {'grammar': 2, 'vocabulary': 5},
        ),
      ],
      abilityReport: ability,
      activeMistakeCount: 1,
    );

    final snapshot = AdaptiveLearningEngine.buildSnapshot(
      learningItems: [
        LearningItem(
          id: '1',
          text: 'Yesterday I went home.',
          createdAt: now.subtract(const Duration(days: 3)),
          nextReviewAt: now.subtract(const Duration(hours: 1)),
        ),
      ],
      abilityReport: ability,
      progressReport: report,
      mistakes: [
        MistakeRecord(
          taskId: 'grammar-past',
          type: 'grammar',
          title: '文法加強 · 過去式',
          prompt: 'Yesterday I ___ home.',
          answer: 'went',
          explanation: 'Yesterday 對應過去式 went。',
          wrongCount: 2,
          correctStreak: 0,
          lastWrongAt: now,
        ),
      ],
      weaknesses: [
        WeaknessRecord(
          category: '時態',
          count: 3,
          example: 'Yesterday I go home.',
          correction: 'Yesterday I went home.',
          explanation: '過去式',
          lastSeenAt: now,
        ),
      ],
      dailyGoal: 10,
      now: now,
    );

    expect(snapshot.course, hasLength(7));
    expect(snapshot.memory.summary, contains('過去式'));
    expect(snapshot.dueReviewCount, 1);
    expect(snapshot.difficulty, inInclusiveRange(1, 10));
    expect(snapshot.coachMessage, isNotEmpty);
  });

  testWidgets('adaptive learning center renders V1.25 through V1.30',
      (tester) async {
    final report = progressReport();
    final snapshot = AdaptiveLearningEngine.buildSnapshot(
      learningItems: const [],
      abilityReport: report.abilityReport,
      progressReport: report,
      mistakes: const [],
      weaknesses: const [],
      dailyGoal: 10,
      now: DateTime(2026, 9, 28, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveLearningScreen(
          snapshot: snapshot,
          onAction: (_) {},
        ),
      ),
    );

    expect(find.text('V1.25 · 智慧複習 2.0'), findsOneWidget);
    expect(find.text('V1.26 · Shili 主動教練'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('v127-speaking-score')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('V1.27 · 口說評分'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('v128-seven-day-course')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('V1.28 · AI 7 天個人課程'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('v129-learning-memory')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('V1.29 · Shili 學習記憶'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('v130-adaptive-engine')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('V1.30 · 自適應學習引擎 1.0'), findsOneWidget);
  });

  testWidgets('V1.29 learner memory is injected into Shili scenario',
      (tester) async {
    String? sentScenario;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatScreen(
            proactiveCoachMessage: '今天先補強過去式。',
            learnerMemory: '優先能力：過去式；已掌握：單字・片語',
            onSend: (message, language, scenario, history) async {
              sentScenario = scenario;
              return const AiCoachReply(
                reply: 'Good start.',
                correction: '',
                explanation: '',
                translation: '很好的開始。',
              );
            },
            onSaveLearning: (_) async => true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('proactive-shili-coach')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('start-coach-recommendation')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('start-speaking-assessment')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('toggle-proactive-coach')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('start-coach-recommendation')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('start-speaking-assessment')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('toggle-proactive-coach')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('chat-input')),
      'Yesterday I went home.',
    );
    await tester.tap(find.byKey(const ValueKey('send-chat-message')));
    await tester.pumpAndSettle();

    expect(sentScenario, contains('Learner memory'));
    expect(sentScenario, contains('過去式'));
  });

  testWidgets('V1.30 training reorders matching type after two misses',
      (tester) async {
    const plan = DailyTrainingPlan(
      tasks: [
        DailyTrainingTask(
          id: 'v1',
          type: 'vocabulary',
          title: '單字・片語',
          prompt: 'first',
          answer: '一',
          options: ['一', '二'],
          correctIndex: 0,
        ),
        DailyTrainingTask(
          id: 'v2',
          type: 'vocabulary',
          title: '單字・片語',
          prompt: 'second',
          answer: '二',
          options: ['二', '三'],
          correctIndex: 0,
        ),
        DailyTrainingTask(
          id: 'g1',
          type: 'grammar',
          title: '文法加強 · 過去式',
          prompt: 'grammar-next',
          answer: 'went',
          options: ['went', 'go'],
          correctIndex: 0,
        ),
        DailyTrainingTask(
          id: 'v3',
          type: 'vocabulary',
          title: '單字・片語',
          prompt: 'vocab-boost',
          answer: '三',
          options: ['三', '四'],
          correctIndex: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DailyTrainingScreen(
          plan: plan,
          onReviewResult: (_, __) async {},
          onTaskResult: (_, __) async {},
          onCompleted: (_) async {},
        ),
      ),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('daily-choice-1')),
    );
    await tester.tap(find.byKey(const ValueKey('daily-choice-1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('daily-next-task')),
    );
    await tester.tap(find.byKey(const ValueKey('daily-next-task')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daily-choice-1')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('adaptive-training-notice')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('daily-next-task')));
    await tester.pumpAndSettle();

    expect(find.text('vocab-boost'), findsOneWidget);
    expect(find.text('grammar-next'), findsNothing);
  });
}
