import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguamate/models/adaptive_learning.dart';
import 'package:linguamate/models/cloud_session.dart';
import 'package:linguamate/models/daily_training.dart';
import 'package:linguamate/models/learning_ability.dart';
import 'package:linguamate/models/learning_progress.dart';
import 'package:linguamate/models/roleplay_mission.dart';
import 'package:linguamate/screens/ai_chat_screen.dart';
import 'package:linguamate/screens/course_plan_screen.dart';
import 'package:linguamate/services/adaptive_course_generator.dart';
import 'package:linguamate/services/course_progress_store.dart';
import 'package:linguamate/services/speaking_history_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('V1.33 speaking history persists score details', () async {
    const store = SpeakingHistoryStore();
    const assessment = PronunciationAssessment(
      target: 'I need to check the machine.',
      transcript: 'I need check the machine.',
      completeness: 83,
      fluency: 90,
      score: 86,
      missingWords: ['to'],
      naturalSuggestion: 'I need to check the machine.',
    );

    final saved = await store.append(
      assessment,
      now: DateTime(2026, 9, 28, 12),
    );
    final loaded = await store.load();

    expect(saved, hasLength(1));
    expect(loaded, hasLength(1));
    expect(loaded.first.score, 86);
    expect(loaded.first.missingWords, ['to']);
  });

  test('V1.34 roleplay changes branch from learner response', () {
    const mission = RoleplayMission(
      id: 'test',
      title: '主管追問',
      baseScenario: '工作職場',
      yourRole: '工程師',
      shiliRole: '主管',
      goal: '說明問題並提出方案',
      suggestedOpening: 'I need to report an issue.',
      stages: ['說明問題', '回答追問', '提出方案'],
    );

    final normal = mission.backendScenarioFor(
      userTurns: 1,
      learnerMessage: 'The line is running now.',
    );
    final problem = mission.backendScenarioFor(
      userTurns: 1,
      learnerMessage: 'We have a problem and the machine cannot run.',
    );

    expect(normal, contains('順利推進分支'));
    expect(problem, contains('問題處理分支'));
    expect(problem, contains('回答追問'));
  });

  test('V1.35 adaptive course generator creates chapter sequence', () {
    const ability = LearningAbilityReport(
      records: <LearningAbilityRecord>[],
    );
    const progress = LearningProgressReport(
      history: <DailyTrainingSummary>[],
      abilityReport: ability,
      activeMistakeCount: 0,
    );

    final plan = AdaptiveCourseGenerator.generate(
      abilityReport: ability,
      progressReport: progress,
      mistakes: const [],
      weaknesses: const [],
    );

    expect(plan.chapters, hasLength(4));
    expect(plan.chapters.first.lessons, hasLength(5));
    expect(plan.chapters.first.lessons.map((item) => item.type), containsAll(
      ['vocabulary', 'grammar', 'speaking', 'roleplay', 'quiz'],
    ));
  });

  testWidgets('V1.35 course unlocks chapters in order', (tester) async {
    const ability = LearningAbilityReport(
      records: <LearningAbilityRecord>[],
    );
    const progress = LearningProgressReport(
      history: <DailyTrainingSummary>[],
      abilityReport: ability,
      activeMistakeCount: 0,
    );
    final plan = AdaptiveCourseGenerator.generate(
      abilityReport: ability,
      progressReport: progress,
      mistakes: const [],
      weaknesses: const [],
    );
    const store = CourseProgressStore();

    await tester.pumpWidget(
      MaterialApp(
        home: CoursePlanScreen(
          plan: plan,
          initialCompleted: const <String>{},
          onCompleteChapter: store.complete,
          onAction: (_) {},
        ),
      ),
    );

    final second = find.byKey(
      const ValueKey('course-chapter-repair'),
    );
    await tester.scrollUntilVisible(
      second,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final secondCard = tester.widget<Card>(second);
    expect(secondCard, isNotNull);

    await tester.scrollUntilVisible(
      find.text('完成本章並解鎖下一章').first,
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('完成本章並解鎖下一章').first);
    await tester.pumpAndSettle();

    final buttons = tester.widgetList<FilledButton>(
      find.widgetWithText(FilledButton, '完成本章並解鎖下一章'),
    );
    expect(buttons.any((button) => button.onPressed != null), isTrue);
  });

  testWidgets('V1.32 retries AI once and preserves failed draft',
      (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatScreen(
            onSend: (_, __, ___, ____) async {
              calls++;
              throw Exception('temporary outage');
            },
            onSaveLearning: (_) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('chat-input')),
      'Please try this.',
    );
    await tester.tap(find.byKey(const ValueKey('send-chat-message')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.byKey(const ValueKey('retry-failed-chat')), findsOneWidget);
    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('chat-input')),
    );
    expect(input.controller?.text, 'Please try this.');
  });

  test('V1.36 cloud session round-trips safely', () {
    const session = CloudSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      userId: 'user-id',
      email: 'learner@example.com',
    );
    final restored = CloudSession.fromJson(session.toJson());

    expect(restored.isValid, isTrue);
    expect(restored.email, 'learner@example.com');
    expect(restored.userId, 'user-id');
  });
}
