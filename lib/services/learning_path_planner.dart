import '../models/learning_ability.dart';
import '../models/learning_path.dart';
import '../models/learning_progress.dart';
import '../models/mistake_record.dart';

class LearningPathPlanner {
  const LearningPathPlanner._();

  static LearningPathPlan build({
    required LearningAbilityReport abilityReport,
    required LearningProgressReport progressReport,
    required List<MistakeRecord> mistakes,
  }) {
    final steps = <LearningPathStep>[];
    final priority = abilityReport.priority;
    final activeMistakes = mistakes.where((item) => item.isActive).length;

    if (priority != null) {
      steps.add(
        LearningPathStep(
          id: 'focus',
          title: '先補強 ${priority.label}',
          reason:
              '目前熟練度 ${priority.score}% · 答對率 ${(priority.accuracy * 100).round()}%，今天先把最弱的一塊補起來。',
          action: 'daily',
          actionLabel: '開始今日訓練',
        ),
      );
    } else {
      steps.add(
        const LearningPathStep(
          id: 'start',
          title: '先建立你的能力基準',
          reason: '完成一組今日訓練後，LinguaMate 就能開始替你安排學習順序。',
          action: 'daily',
          actionLabel: '開始第一組訓練',
        ),
      );
    }

    if (activeMistakes > 0) {
      steps.add(
        LearningPathStep(
          id: 'mistakes',
          title: '清掉 $activeMistakes 個待加強錯題',
          reason: '錯題是最值得優先回收的學習材料，先把重複失誤壓下來。',
          action: 'mistakes',
          actionLabel: '只練錯題',
        ),
      );
    } else {
      steps.add(
        const LearningPathStep(
          id: 'conversation',
          title: '用 Shili 補充新素材',
          reason: '目前沒有待加強錯題，可以透過自然對話繼續增加單字與文法素材。',
          action: 'ai',
          actionLabel: '找 Shili 練習',
        ),
      );
    }

    final roleplayReason = priority?.type == 'grammar'
        ? '把剛練過的文法放進真實情境，會比單純背規則更容易留下來。'
        : priority?.type == 'vocabulary'
            ? '把新單字放進情境任務裡使用，讓它從「看得懂」變成「說得出」。'
            : '用角色扮演把單字、文法與反應速度一起整合。';

    steps.add(
      LearningPathStep(
        id: 'roleplay',
        title: '完成 1 個 AI 情境任務',
        reason: roleplayReason,
        action: 'roleplay',
        actionLabel: '進入情境任務',
      ),
    );

    return LearningPathPlan(
      steps: steps.take(3).toList(growable: false),
    );
  }
}
