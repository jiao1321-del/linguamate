import '../models/gamification.dart';
import '../models/intelligence_core.dart';
import '../models/learner_memory_profile.dart';
import '../models/learning_insights.dart';
import '../models/learning_item.dart';
import '../models/mistake_record.dart';

class IntelligenceCoreEngine {
  const IntelligenceCoreEngine._();

  static IntelligenceCoreSnapshot build({
    required LearnerMemoryProfile memory,
    required LearningInsightsSnapshot insights,
    required GamificationSnapshot gamification,
    required List<LearningItem> learningItems,
    required List<MistakeRecord> mistakes,
    required int adaptiveDifficulty,
    required Set<String> roadmapCompleted,
    required Set<String> campaignCompleted,
    required Set<String> courseCompleted,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final dueReviews =
        learningItems.where((item) => item.isDue(reference)).length;
    final activeMistakes = mistakes.where((item) => item.isActive).length;

    final action = _nextBestAction(
      memory: memory,
      insights: insights,
      dueReviews: dueReviews,
      activeMistakes: activeMistakes,
      roadmapCompleted: roadmapCompleted.length,
      campaignCompleted: campaignCompleted.length,
      courseCompleted: courseCompleted.length,
    );

    return IntelligenceCoreSnapshot(
      nextBestAction: action,
      memory: memory,
      insights: insights,
      gamification: gamification,
      adaptiveDifficulty: adaptiveDifficulty,
      dueReviewCount: dueReviews,
      activeMistakeCount: activeMistakes,
      roadmapProgress: roadmapCompleted.length,
      campaignProgress: campaignCompleted.length,
      courseProgress: courseCompleted.length,
    );
  }

  static NextBestAction _nextBestAction({
    required LearnerMemoryProfile memory,
    required LearningInsightsSnapshot insights,
    required int dueReviews,
    required int activeMistakes,
    required int roadmapCompleted,
    required int campaignCompleted,
    required int courseCompleted,
  }) {
    if (activeMistakes > 0) {
      return NextBestAction(
        action: 'mistakes',
        title: '先收回高優先錯題',
        reason: '目前有 $activeMistakes 個待加強錯題，先處理它們能最快降低重複失誤。',
        estimatedMinutes: 5,
      );
    }

    if (dueReviews >= 5) {
      return NextBestAction(
        action: 'daily',
        title: '清掉今天到期的記憶',
        reason: '有 $dueReviews 個收藏已到複習時間，現在複習最能避免遺忘。',
        estimatedMinutes: 6,
      );
    }

    if (memory.staleSkills.isNotEmpty) {
      return NextBestAction(
        action: 'daily',
        title: '重新喚醒「${memory.staleSkills.first}」',
        reason: '這項能力已經一段時間沒練，熟練度正在衰退。',
        estimatedMinutes: 5,
      );
    }

    if (insights.speakingAverage == 0) {
      return const NextBestAction(
        action: 'liveVoice',
        title: '建立第一次 Live Voice 基準',
        reason: '目前還沒有足夠的口說資料，先用一段短對話建立基準。',
        estimatedMinutes: 4,
      );
    }

    if (insights.speakingAverage < 78) {
      return NextBestAction(
        action: 'speaking',
        title: '做一輪 Shadowing',
        reason:
            '近 30 天口說平均 ${insights.speakingAverage} 分，現在最值得把句子完整度練穩。',
        estimatedMinutes: 5,
      );
    }

    if (roadmapCompleted < 7) {
      return const NextBestAction(
        action: 'roadmap',
        title: '推進 30 天學習路線',
        reason: '目前基礎狀態穩定，繼續完成長期路線能把學習節奏固定下來。',
        estimatedMinutes: 8,
      );
    }

    if (campaignCompleted < 3) {
      return const NextBestAction(
        action: 'campaign',
        title: '進入語言 RPG 實戰',
        reason: '基礎練習已累積足夠，現在適合把能力放進連續情境。',
        estimatedMinutes: 10,
      );
    }

    if (courseCompleted < 4) {
      return const NextBestAction(
        action: 'course',
        title: '完成下一個 AI 課程章節',
        reason: '用章節式學習把素材、句型、口說和情境串在一起。',
        estimatedMinutes: 10,
      );
    }

    return const NextBestAction(
      action: 'daily',
      title: '自適應綜合挑戰',
      reason: '目前沒有明顯短板，讓引擎用最新資料自動決定下一組題目。',
      estimatedMinutes: 7,
    );
  }
}
