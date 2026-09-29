import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguamate/models/daily_training.dart';
import 'package:linguamate/models/learning_ability.dart';
import 'package:linguamate/models/learning_growth.dart';
import 'package:linguamate/models/learning_progress.dart';
import 'package:linguamate/screens/growth_center_screen.dart';

void main() {
  LearningProgressReport buildReport() {
    return LearningProgressReport(
      history: [
        DailyTrainingSummary(
          dateKey: '2026-09-21',
          totalTasks: 8,
          correctTasks: 6,
          completedAt: DateTime(2026, 9, 21, 9),
          typeTotals: const {'vocabulary': 4, 'grammar': 4},
          typeCorrect: const {'vocabulary': 3, 'grammar': 3},
        ),
        DailyTrainingSummary(
          dateKey: '2026-09-27',
          totalTasks: 10,
          correctTasks: 8,
          completedAt: DateTime(2026, 9, 27, 9),
          typeTotals: const {'vocabulary': 5, 'grammar': 5},
          typeCorrect: const {'vocabulary': 5, 'grammar': 3},
        ),
        DailyTrainingSummary(
          dateKey: '2026-09-28',
          totalTasks: 10,
          correctTasks: 9,
          completedAt: DateTime(2026, 9, 28, 9),
          typeTotals: const {'vocabulary': 5, 'grammar': 5},
          typeCorrect: const {'vocabulary': 5, 'grammar': 4},
        ),
      ],
      abilityReport: const LearningAbilityReport(
        records: <LearningAbilityRecord>[],
      ),
      activeMistakeCount: 0,
    );
  }

  test('V1.20-V1.24 growth snapshot derives goals, XP, badges and weekly data',
      () {
    final snapshot = LearningGrowthSnapshot.fromReport(
      report: buildReport(),
      now: DateTime(2026, 9, 28, 12),
      dailyGoal: 10,
    );

    expect(snapshot.todayTasks, 10);
    expect(snapshot.dailyGoalCompleted, isTrue);
    expect(snapshot.streak, 2);
    expect(snapshot.level, greaterThanOrEqualTo(2));
    expect(snapshot.xp, greaterThan(0));
    expect(snapshot.weeklyDays, 2);
    expect(snapshot.weeklyTasks, 20);
    expect(snapshot.weeklyAccuracy, 85);
    expect(snapshot.bestSkillLabel, '單字・片語');
    expect(snapshot.badges.first.unlocked, isTrue);
    expect(
      snapshot.badges
          .firstWhere((badge) => badge.id == 'accuracy-80')
          .unlocked,
      isTrue,
    );
    expect(
      snapshot.badges
          .firstWhere((badge) => badge.id == 'clear-mistakes')
          .unlocked,
      isTrue,
    );
    expect(snapshot.calendar, hasLength(28));
    expect(snapshot.calendar.last.tasks, 10);
  });

  testWidgets('GrowthCenterScreen renders all five version modules',
      (tester) async {
    var selectedGoal = 10;

    await tester.pumpWidget(
      MaterialApp(
        home: GrowthCenterScreen(
          report: buildReport(),
          initialDailyGoal: 10,
          now: DateTime(2026, 9, 28, 12),
          onDailyGoalChanged: (goal) async {
            selectedGoal = goal;
          },
        ),
      ),
    );

    expect(find.text('V1.20 · 每日目標'), findsOneWidget);
    expect(find.text('V1.21 · XP 與等級'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('achievement-card')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('V1.22 · 成就徽章'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('weekly-insight-card')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('V1.23 · 近 7 天週報'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('learning-calendar-card')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('V1.24 · 28 天學習日曆'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('daily-goal-15')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('daily-goal-15')));
    await tester.pumpAndSettle();

    expect(selectedGoal, 15);
    expect(find.text('10 / 15 題'), findsOneWidget);
  });
}
