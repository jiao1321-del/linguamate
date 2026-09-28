import '../models/adaptive_learning.dart';
import '../models/ai_coach_reply.dart';
import '../models/daily_training.dart';
import '../models/learning_ability.dart';
import '../models/learning_item.dart';
import '../models/learning_progress.dart';
import '../models/mistake_record.dart';
import '../models/weakness_record.dart';
import 'daily_training_plan_builder.dart';

class AdaptiveLearningEngine {
  const AdaptiveLearningEngine._();

  static AdaptiveLearningSnapshot buildSnapshot({
    required List<LearningItem> learningItems,
    required LearningAbilityReport abilityReport,
    required LearningProgressReport progressReport,
    required List<MistakeRecord> mistakes,
    required List<WeaknessRecord> weaknesses,
    required int dailyGoal,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final activeMistakes = mistakes.where((item) => item.isActive).length;
    final dueReviewCount =
        learningItems.where((item) => item.isDue(reference)).length;
    final priority = abilityReport.priority;
    final speaking = abilityReport.records
        .where((item) => item.type == 'speaking')
        .toList(growable: false);
    final speakingAttempts =
        speaking.fold(0, (sum, item) => sum + item.attempts);
    final speakingCorrect =
        speaking.fold(0, (sum, item) => sum + item.correctCount);
    final speakingAccuracy = speakingAttempts == 0
        ? 0
        : ((speakingCorrect / speakingAttempts) * 100).round();

    final stage = _stageFor(
      tasks: progressReport.totalTasks,
      accuracy: progressReport.overallAccuracy,
      completedDays: progressReport.completedDays,
    );
    final difficulty = _difficultyFor(
      tasks: progressReport.totalTasks,
      accuracy: progressReport.overallAccuracy,
      mastered: abilityReport.masteredCount,
    );

    final mastered = abilityReport.records
        .where((item) => item.status == AbilityStatus.mastered)
        .map((item) => item.label)
        .take(4)
        .toList(growable: false);
    final topWeakness =
        weaknesses.isEmpty ? null : weaknesses.first.category.trim();

    final memoryParts = <String>[
      '目前階段：$stage',
      if (priority != null) '優先能力：${priority.label}',
      if (mastered.isNotEmpty) '已掌握：${mastered.join('、')}',
      if (topWeakness?.isNotEmpty == true) '常見弱點：$topWeakness',
      '收藏 ${learningItems.length} 句',
      '待加強錯題 $activeMistakes 題',
      if (speakingAttempts > 0)
        '口說練習 $speakingAttempts 次，通過率 $speakingAccuracy%',
    ];

    final memory = LearnerMemorySummary(
      summary: memoryParts.join('；'),
      masteredSkills: mastered,
      prioritySkill: priority?.label,
      savedItemCount: learningItems.length,
      activeMistakeCount: activeMistakes,
    );

    final coachMessage = _coachMessage(
      priority: priority,
      activeMistakes: activeMistakes,
      dueReviewCount: dueReviewCount,
      speakingAttempts: speakingAttempts,
      streak: progressReport.streakAt(reference),
    );

    final planReason = priority == null
        ? '先建立能力基準；系統會平均混合單字、文法、弱點與複習。'
        : '目前 ${priority.label} 熟練度 ${priority.score}%，今日題目會優先補強這一塊，再混入錯題與到期複習。';

    final smartReviewReason = dueReviewCount == 0
        ? '目前沒有到期收藏；已熟練內容會自動延長間隔，避免重複刷題。'
        : '今天有 $dueReviewCount 個到期收藏；複習間隔會依整體答對率、連續學習與記憶階段動態調整。';

    final recommendedAction = activeMistakes > 0
        ? 'mistakes'
        : priority != null
            ? 'daily'
            : 'ai';

    return AdaptiveLearningSnapshot(
      stage: stage,
      difficulty: difficulty,
      coachMessage: coachMessage,
      dailyPlanReason: planReason,
      smartReviewReason: smartReviewReason,
      recommendedAction: recommendedAction,
      memory: memory,
      course: _buildSevenDayCourse(
        priority: priority,
        activeMistakes: activeMistakes,
        dueReviewCount: dueReviewCount,
        speakingAttempts: speakingAttempts,
      ),
      dueReviewCount: dueReviewCount,
      activeMistakeCount: activeMistakes,
      speakingAttempts: speakingAttempts,
      speakingAccuracy: speakingAccuracy,
    );
  }

  static DailyTrainingPlan buildDailyPlan({
    required List<LearningItem> learningItems,
    required List<WeaknessRecord> weaknesses,
    required List<AiCoachReply> coachReplies,
    required List<MistakeRecord> mistakes,
    required LearningAbilityReport abilityReport,
    DateTime? now,
  }) {
    final base = DailyTrainingPlanBuilder.build(
      learningItems: learningItems,
      weaknesses: weaknesses,
      coachReplies: coachReplies,
      mistakes: mistakes,
      priorityType: abilityReport.priorityType,
      now: now,
    );

    if (base.tasks.length <= 1) return base;

    final masteredLabels = abilityReport.records
        .where((item) => item.status == AbilityStatus.mastered)
        .map((item) => item.label.toLowerCase())
        .toSet();
    final priorityType = abilityReport.priorityType;

    int score(DailyTrainingTask task) {
      var value = 100;
      if (task.type == priorityType) value -= 40;
      if (mistakes.any((item) => item.taskId == task.id && item.isActive)) {
        value -= 50;
      }
      if (task.type == 'review') value -= 10;

      final normalizedTitle = task.title.toLowerCase();
      if (masteredLabels.any(normalizedTitle.contains)) {
        value += 35;
      }
      if (task.type == 'vocabulary' &&
          masteredLabels.contains('單字・片語')) {
        value += 20;
      }
      return value;
    }

    final sorted = [...base.tasks]
      ..sort((a, b) => score(a).compareTo(score(b)));
    return DailyTrainingPlan(tasks: sorted);
  }

  static AdaptiveReviewDecision reviewItem({
    required LearningItem item,
    required bool remembered,
    required LearningProgressReport progressReport,
    required DateTime now,
  }) {
    if (!remembered) {
      final updated = item.copyWith(
        reviewLevel: 0,
        reviewCount: item.reviewCount + 1,
        lastReviewedAt: now,
        nextReviewAt: now,
      );
      return AdaptiveReviewDecision(
        item: updated,
        intervalDays: 0,
        reason: '這次還不熟，先回到高優先級，讓它更快再次出現。',
      );
    }

    const baseIntervals = <int>[1, 2, 4, 7, 14, 30, 60];
    final nextLevel =
        (item.reviewLevel + 1).clamp(1, baseIntervals.length).toInt();
    var interval = baseIntervals[nextLevel - 1];

    final accuracy = progressReport.overallAccuracy;
    final streak = progressReport.streakAt(now);

    if (progressReport.totalTasks >= 10 && accuracy >= 85) {
      interval = (interval * 1.4).round();
    } else if (progressReport.totalTasks >= 10 && accuracy < 60) {
      interval = (interval * 0.65).round().clamp(1, 60).toInt();
    }

    if (item.reviewCount >= 4 && nextLevel >= 3) {
      interval = (interval * 1.2).round();
    }
    if (streak >= 5 && nextLevel >= 2) {
      interval += 1;
    }
    interval = interval.clamp(1, 90).toInt();

    final updated = item.copyWith(
      reviewLevel: nextLevel,
      reviewCount: item.reviewCount + 1,
      lastReviewedAt: now,
      nextReviewAt: now.add(Duration(days: interval)),
    );

    final reason = accuracy >= 85 && progressReport.totalTasks >= 10
        ? '近期答對率穩定，這張卡自動拉長到 $interval 天後再複習。'
        : accuracy < 60 && progressReport.totalTasks >= 10
            ? '近期答對率偏低，這張卡維持較密集節奏，$interval 天後再出現。'
            : '依目前記憶階段安排 $interval 天後再複習。';

    return AdaptiveReviewDecision(
      item: updated,
      intervalDays: interval,
      reason: reason,
    );
  }

  static PronunciationAssessment assessPronunciation({
    required String target,
    required String transcript,
  }) {
    final targetTokens = _tokens(target);
    final spokenTokens = _tokens(transcript);

    if (targetTokens.isEmpty || spokenTokens.isEmpty) {
      return PronunciationAssessment(
        target: target,
        transcript: transcript,
        completeness: 0,
        fluency: 0,
        score: 0,
        missingWords: targetTokens,
        naturalSuggestion: target,
      );
    }

    final spokenSet = spokenTokens.toSet();
    final missing = <String>[];
    var matched = 0;
    for (final word in targetTokens) {
      if (spokenSet.contains(word)) {
        matched++;
      } else if (!missing.contains(word)) {
        missing.add(word);
      }
    }
    final completeness =
        ((matched / targetTokens.length) * 100).round().clamp(0, 100).toInt();

    var sequenceMatches = 0;
    var cursor = 0;
    for (final word in spokenTokens) {
      for (var i = cursor; i < targetTokens.length; i++) {
        if (targetTokens[i] == word) {
          sequenceMatches++;
          cursor = i + 1;
          break;
        }
      }
    }
    final maxLength = targetTokens.length > spokenTokens.length
        ? targetTokens.length
        : spokenTokens.length;
    final fluency =
        ((sequenceMatches / maxLength) * 100).round().clamp(0, 100).toInt();
    final score = ((completeness * 0.65) + (fluency * 0.35))
        .round()
        .clamp(0, 100)
        .toInt();

    return PronunciationAssessment(
      target: target,
      transcript: transcript,
      completeness: completeness,
      fluency: fluency,
      score: score,
      missingWords: missing.take(6).toList(growable: false),
      naturalSuggestion: target,
    );
  }

  static List<String> _tokens(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9']+"), ' ')
      .split(' ')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  static String _stageFor({
    required int tasks,
    required int accuracy,
    required int completedDays,
  }) {
    if (tasks < 20 || completedDays < 3) return '建立基礎';
    if (tasks < 80 || accuracy < 70) return '穩定累積';
    if (tasks < 200 || accuracy < 82) return '實戰整合';
    return '進階強化';
  }

  static int _difficultyFor({
    required int tasks,
    required int accuracy,
    required int mastered,
  }) {
    var value = 1;
    if (tasks >= 20) value++;
    if (tasks >= 80 && accuracy >= 65) value++;
    if (tasks >= 160 && accuracy >= 75) value++;
    if (mastered >= 4 && accuracy >= 82) value++;
    return value.clamp(1, 5).toInt();
  }

  static String _coachMessage({
    required LearningAbilityRecord? priority,
    required int activeMistakes,
    required int dueReviewCount,
    required int speakingAttempts,
    required int streak,
  }) {
    if (activeMistakes >= 3) {
      return '你現在有 $activeMistakes 個高優先錯題，我建議先用 3～5 分鐘把最常錯的內容收回來。';
    }
    if (dueReviewCount >= 5) {
      return '今天有 $dueReviewCount 個內容到期，先完成一輪智慧複習，會比直接學新內容更划算。';
    }
    if (priority != null) {
      return '你目前最值得補強的是「${priority.label}」。今天先練這一塊，再用 Shili 做一次情境應用。';
    }
    if (speakingAttempts == 0) {
      return '你的基礎訓練已經有資料了，下一步可以加入第一次口說評分，建立口說基準。';
    }
    if (streak >= 3) {
      return '你已連續學習 $streak 天，今天適合把難度提高一點，做綜合實戰。';
    }
    return '今天先完成一組自適應訓練，我會依結果重新安排下一步。';
  }

  static List<AdaptiveCourseDay> _buildSevenDayCourse({
    required LearningAbilityRecord? priority,
    required int activeMistakes,
    required int dueReviewCount,
    required int speakingAttempts,
  }) {
    final focus = priority?.label ?? '能力基準';
    return <AdaptiveCourseDay>[
      AdaptiveCourseDay(
        day: 1,
        title: '智慧回收',
        focus: dueReviewCount > 0 ? '到期複習' : focus,
        reason: dueReviewCount > 0
            ? '先清掉今天到期的記憶負債。'
            : '先從目前優先能力建立今天的節奏。',
        action: 'daily',
      ),
      AdaptiveCourseDay(
        day: 2,
        title: '弱點補強',
        focus: activeMistakes > 0 ? '錯題回收' : focus,
        reason: activeMistakes > 0
            ? '集中處理最容易重複失誤的內容。'
            : '沒有明顯錯題時，改練最弱能力。',
        action: activeMistakes > 0 ? 'mistakes' : 'daily',
      ),
      AdaptiveCourseDay(
        day: 3,
        title: '口說基準',
        focus: speakingAttempts == 0 ? '第一次口說評分' : '口說穩定度',
        reason: '把看得懂的句子轉成真正說得出口。',
        action: 'speaking',
      ),
      const AdaptiveCourseDay(
        day: 4,
        title: '素材擴充',
        focus: '單字＋片語',
        reason: '用 Shili 對話補充真實會用到的新素材。',
        action: 'ai',
      ),
      AdaptiveCourseDay(
        day: 5,
        title: '規則整理',
        focus: focus,
        reason: '把近期文法與弱點重新整理成可操作的規則。',
        action: 'daily',
      ),
      const AdaptiveCourseDay(
        day: 6,
        title: '情境實戰',
        focus: 'AI 角色任務',
        reason: '把單字、文法與反應速度放進真實情境。',
        action: 'roleplay',
      ),
      const AdaptiveCourseDay(
        day: 7,
        title: '自適應挑戰',
        focus: '綜合測試',
        reason: '依前六天結果重新混題，決定下一週難度。',
        action: 'daily',
      ),
    ];
  }
}
