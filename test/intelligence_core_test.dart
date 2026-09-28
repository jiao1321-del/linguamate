import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linguamate/models/adaptive_learning.dart';
import 'package:linguamate/models/daily_training.dart';
import 'package:linguamate/models/gamification.dart';
import 'package:linguamate/models/intelligence_core.dart';
import 'package:linguamate/models/learner_memory_profile.dart';
import 'package:linguamate/models/learning_ability.dart';
import 'package:linguamate/models/learning_insights.dart';
import 'package:linguamate/models/learning_item.dart';
import 'package:linguamate/models/learning_progress.dart';
import 'package:linguamate/models/mistake_record.dart';
import 'package:linguamate/models/roleplay_campaign.dart';
import 'package:linguamate/models/speaking_attempt.dart';
import 'package:linguamate/models/training_telemetry.dart';
import 'package:linguamate/models/weakness_record.dart';
import 'package:linguamate/screens/intelligence_hub_screen.dart';
import 'package:linguamate/services/adaptive_learning_engine.dart';
import 'package:linguamate/services/cloud_payload_merger.dart';
import 'package:linguamate/services/gamification_engine.dart';
import 'package:linguamate/services/intelligence_core_engine.dart';
import 'package:linguamate/services/learner_memory_engine.dart';
import 'package:linguamate/services/learning_insights_engine.dart';
import 'package:linguamate/services/roadmap_30_generator.dart';

void main() {
  const emptyAbility = LearningAbilityReport(
    records: <LearningAbilityRecord>[],
  );

  LearningProgressReport emptyProgress() => const LearningProgressReport(
        history: <DailyTrainingSummary>[],
        abilityReport: emptyAbility,
        activeMistakeCount: 0,
      );

  test('V1.37 cloud merger unions lists without destructive overwrite', () {
    final local = <String, dynamic>{
      'syncedAt': '2026-09-28T08:00:00Z',
      'savedItems': [
        {
          'id': 'local-card',
          'text': 'Hello',
          'createdAt': '2026-09-28T08:00:00Z',
        },
      ],
      'courseCompleted': ['foundation'],
      'dailyGoal': 10,
    };
    final cloud = <String, dynamic>{
      'syncedAt': '2026-09-28T09:00:00Z',
      'savedItems': [
        {
          'id': 'cloud-card',
          'text': 'Good morning',
          'createdAt': '2026-09-28T09:00:00Z',
        },
      ],
      'courseCompleted': ['repair'],
      'dailyGoal': 15,
    };

    final merged = CloudPayloadMerger.merge(local, cloud);
    final saved = merged['savedItems'] as List<dynamic>;
    final completed = merged['courseCompleted'] as List<dynamic>;

    expect(saved, hasLength(2));
    expect(completed.toSet(), {'foundation', 'repair'});
    expect(merged['dailyGoal'], 15);
    expect(merged['schemaVersion'], 146);
  });

  test('V1.38 learner memory decays stale mastered skills', () {
    final now = DateTime(2026, 9, 28);
    final profile = LearnerMemoryEngine.build(
      abilities: [
        LearningAbilityRecord(
          key: 'grammar:past',
          label: '過去式',
          type: 'grammar',
          attempts: 20,
          correctCount: 19,
          wrongCount: 1,
          correctStreak: 8,
          lastResultCorrect: true,
          lastPracticedAt: now.subtract(const Duration(days: 35)),
        ),
        LearningAbilityRecord(
          key: 'vocabulary',
          label: '單字・片語',
          type: 'vocabulary',
          attempts: 20,
          correctCount: 18,
          wrongCount: 2,
          correctStreak: 4,
          lastResultCorrect: true,
          lastPracticedAt: now,
        ),
      ],
      weaknesses: const <WeaknessRecord>[],
      mistakes: const <MistakeRecord>[],
      speaking: const <SpeakingAttempt>[],
      savedItems: const <LearningItem>[],
      now: now,
    );

    expect(profile.staleSkills, contains('過去式'));
    expect(profile.masteredSkills, contains('單字・片語'));
    expect(profile.summary, contains('久未練習'));
  });

  test('V1.39 speaking diagnostics marks correct missing and extra words', () {
    final result = AdaptiveLearningEngine.assessPronunciation(
      target: 'I need to check the machine',
      transcript: 'I really need check the machine',
    );

    expect(
      result.wordFeedback.any(
        (item) =>
            item.word == 'to' &&
            item.status == SpeakingTokenStatus.missing,
      ),
      isTrue,
    );
    expect(
      result.wordFeedback.any(
        (item) =>
            item.word == 'really' &&
            item.status == SpeakingTokenStatus.extra,
      ),
      isTrue,
    );
    expect(
      result.wordFeedback.any(
        (item) =>
            item.word == 'machine' &&
            item.status == SpeakingTokenStatus.correct,
      ),
      isTrue,
    );
  });

  test('V1.41 overseas-work RPG exposes six connected chapters', () {
    const campaign = RoleplayCampaign.overseasWork;
    expect(campaign.chapters, hasLength(6));
    expect(campaign.chapters.first.missionId, 'work-interview');
    expect(campaign.chapters.last.missionId, 'work-customer');
  });

  test('V1.42 adaptive difficulty uses speed and hint telemetry', () {
    final now = DateTime(2026, 9, 28, 12);
    final fast = [
      for (var i = 0; i < 20; i++)
        TrainingTelemetry(
          id: 'fast-$i',
          taskId: 'task-$i',
          type: 'grammar',
          correct: true,
          responseMs: 3500,
          usedHint: false,
          recordedAt: now,
        ),
    ];
    final slow = [
      for (var i = 0; i < 20; i++)
        TrainingTelemetry(
          id: 'slow-$i',
          taskId: 'task-$i',
          type: 'grammar',
          correct: i < 8,
          responseMs: 23000,
          usedHint: true,
          recordedAt: now,
        ),
    ];

    final fastSnapshot = AdaptiveLearningEngine.buildSnapshot(
      learningItems: const [],
      abilityReport: emptyAbility,
      progressReport: emptyProgress(),
      mistakes: const [],
      weaknesses: const [],
      dailyGoal: 10,
      telemetry: fast,
      now: now,
    );
    final slowSnapshot = AdaptiveLearningEngine.buildSnapshot(
      learningItems: const [],
      abilityReport: emptyAbility,
      progressReport: emptyProgress(),
      mistakes: const [],
      weaknesses: const [],
      dailyGoal: 10,
      telemetry: slow,
      now: now,
    );

    expect(fastSnapshot.difficulty, inInclusiveRange(1, 10));
    expect(slowSnapshot.difficulty, inInclusiveRange(1, 10));
    expect(fastSnapshot.difficulty, greaterThan(slowSnapshot.difficulty));
  });

  test('V1.43 roadmap generates all 30 days and four checkpoints', () {
    final plan = Roadmap30Generator.generate(
      goal: '工作英文',
      priority: '文法',
      weakness: '自然用法',
    );

    expect(plan.days, hasLength(30));
    expect(plan.days.where((item) => item.checkpoint), hasLength(4));
    expect(plan.days.last.day, 30);
  });

  test('V1.44 gamification creates daily and weekly quests', () {
    final snapshot = GamificationEngine.build(
      progress: emptyProgress(),
      speaking: const [],
      dailyGoal: 10,
      courseCompleted: const {'foundation'},
      campaignCompleted: const {'work-interview'},
      roadmapCompleted: const {'工作英文::1'},
      now: DateTime(2026, 9, 28),
    );

    expect(snapshot.level, greaterThanOrEqualTo(1));
    expect(snapshot.dailyQuests, hasLength(3));
    expect(snapshot.weeklyQuests, hasLength(3));
    expect(snapshot.title, isNotEmpty);
  });

  test('V1.45 learning intelligence returns weekly next actions', () {
    final now = DateTime(2026, 9, 28, 12);
    final history = [
      DailyTrainingSummary(
        dateKey: '2026-09-28',
        totalTasks: 10,
        correctTasks: 6,
        completedAt: now,
        typeTotals: const {'grammar': 5, 'vocabulary': 5},
        typeCorrect: const {'grammar': 2, 'vocabulary': 4},
      ),
    ];
    final progress = LearningProgressReport(
      history: history,
      abilityReport: emptyAbility,
      activeMistakeCount: 0,
    );

    final insights = LearningInsightsEngine.build(
      progress: progress,
      abilities: const [],
      mistakes: const [],
      speaking: const [],
      telemetry: const [],
      now: now,
    );

    expect(insights.tasks7, 10);
    expect(insights.accuracy7, 60);
    expect(insights.nextActions, isNotEmpty);
    expect(insights.weeklyReport, contains('10 題'));
  });

  test('V1.46 intelligence core prioritizes active mistakes', () {
    final now = DateTime(2026, 9, 28);
    final mistake = MistakeRecord(
      taskId: 'g1',
      type: 'grammar',
      title: '過去式',
      prompt: 'Yesterday I ___ home.',
      answer: 'went',
      explanation: 'Use past tense.',
      wrongCount: 3,
      correctStreak: 0,
      lastWrongAt: now,
    );
    const insights = LearningInsightsSnapshot(
      tasks7: 10,
      tasks30: 20,
      days7: 2,
      days30: 4,
      accuracy7: 70,
      accuracy30: 70,
      estimatedMinutes30: 15,
      speakingAverage: 82,
      fastestImproving: '文法 +5%',
      staleAbility: '近期能力都有練習',
      topMistake: '過去式',
      weeklyReport: '穩定學習中',
      nextActions: ['補錯題'],
    );
    const game = GamificationSnapshot(
      xp: 100,
      level: 1,
      xpIntoLevel: 100,
      xpPerLevel: 300,
      title: 'Language Starter',
      streak: 2,
      dailyQuests: <LearningQuest>[],
      weeklyQuests: <LearningQuest>[],
    );

    final core = IntelligenceCoreEngine.build(
      memory: LearnerMemoryProfile.empty(),
      insights: insights,
      gamification: game,
      learningItems: const [],
      mistakes: [mistake],
      adaptiveDifficulty: 4,
      roadmapCompleted: const {},
      campaignCompleted: const {},
      courseCompleted: const {},
      now: now,
    );

    expect(core.nextBestAction.action, 'mistakes');
    expect(core.nextBestAction.title, contains('錯題'));
  });

  testWidgets('V1.46 Intelligence Hub renders next best action and modules',
      (tester) async {
    const insights = LearningInsightsSnapshot(
      tasks7: 0,
      tasks30: 0,
      days7: 0,
      days30: 0,
      accuracy7: 0,
      accuracy30: 0,
      estimatedMinutes30: 0,
      speakingAverage: 0,
      fastestImproving: '資料累積中',
      staleAbility: '近期能力都有練習',
      topMistake: '目前沒有高優先錯題',
      weeklyReport: '開始學習',
      nextActions: ['建立口說基準'],
    );
    const game = GamificationSnapshot(
      xp: 0,
      level: 1,
      xpIntoLevel: 0,
      xpPerLevel: 300,
      title: 'Language Starter',
      streak: 0,
      dailyQuests: <LearningQuest>[],
      weeklyQuests: <LearningQuest>[],
    );
    final core = IntelligenceCoreSnapshot(
      nextBestAction: const NextBestAction(
        action: 'liveVoice',
        title: '建立第一次 Live Voice 基準',
        reason: '先建立口說資料。',
        estimatedMinutes: 4,
      ),
      memory: LearnerMemoryProfile.empty(),
      insights: insights,
      gamification: game,
      adaptiveDifficulty: 2,
      dueReviewCount: 0,
      activeMistakeCount: 0,
      roadmapProgress: 0,
      campaignProgress: 0,
      courseProgress: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: IntelligenceHubScreen(
          snapshot: core,
          onAction: (_) {},
          onOpenCloud: () {},
          onOpenMemory: () {},
          onOpenSpeaking: () {},
          onOpenLiveVoice: () {},
          onOpenCampaign: () {},
          onOpenRoadmap: () {},
          onOpenGamification: () {},
          onOpenInsights: () {},
        ),
      ),
    );

    expect(find.text('V1.46 · Next Best Action'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('start-next-best-action')),
      findsOneWidget,
    );
    expect(find.textContaining('V1.37'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('V1.45'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('V1.45'), findsOneWidget);
  });
}
