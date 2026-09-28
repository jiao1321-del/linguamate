import '../models/learning_ability.dart';
import '../models/learning_course.dart';
import '../models/learning_progress.dart';
import '../models/mistake_record.dart';
import '../models/weakness_record.dart';

class AdaptiveCourseGenerator {
  const AdaptiveCourseGenerator._();

  static LearningCoursePlan generate({
    required LearningAbilityReport abilityReport,
    required LearningProgressReport progressReport,
    required List<MistakeRecord> mistakes,
    required List<WeaknessRecord> weaknesses,
  }) {
    final priority = abilityReport.priorityLabel ?? '自然表達';
    final weakness = weaknesses.isEmpty ? priority : weaknesses.first.category;
    final activeMistakes = mistakes.where((item) => item.isActive).length;
    final level = progressReport.totalTasks < 40
        ? '基礎'
        : progressReport.overallAccuracy < 75
            ? '穩定'
            : '實戰';

    return LearningCoursePlan(
      title: 'Shili AI 個人課程 · $level 路線',
      summary:
          '依目前優先能力「$priority」、弱點「$weakness」與 $activeMistakes 個待加強錯題生成。',
      chapters: [
        _chapter(
          id: 'foundation',
          title: 'Chapter 1 · 核心素材',
          focus: priority,
          goal: '先把最常用的字詞與句型整理成可以立即開口的素材。',
          roleplay: '日常生活',
        ),
        _chapter(
          id: 'repair',
          title: 'Chapter 2 · 弱點修復',
          focus: weakness,
          goal: '集中修正常見錯誤，建立穩定且自然的句型反應。',
          roleplay: '工作職場',
        ),
        _chapter(
          id: 'speaking',
          title: 'Chapter 3 · 口說轉化',
          focus: priority,
          goal: '把看得懂的內容轉成說得出口，並用口說分數追蹤進步。',
          roleplay: '日常生活',
        ),
        _chapter(
          id: 'mission',
          title: 'Chapter 4 · 情境實戰',
          focus: weakness,
          goal: '進入分支情境任務，把單字、文法和臨場反應整合起來。',
          roleplay: '工作職場',
        ),
      ],
    );
  }

  static LearningCourseChapter _chapter({
    required String id,
    required String title,
    required String focus,
    required String goal,
    required String roleplay,
  }) {
    return LearningCourseChapter(
      id: id,
      title: title,
      focus: focus,
      goal: goal,
      lessons: [
        LearningCourseLesson(
          type: 'vocabulary',
          title: '素材',
          description: '圍繞「$focus」整理可重複使用的單字與片語。',
          action: 'daily',
        ),
        LearningCourseLesson(
          type: 'grammar',
          title: '句型',
          description: '把「$focus」整理成一條實用規則與短題練習。',
          action: 'daily',
        ),
        const LearningCourseLesson(
          type: 'speaking',
          title: '口說',
          description: '跟讀 Shili 的建議句，記錄完整度、流暢度與漏字。',
          action: 'speaking',
        ),
        LearningCourseLesson(
          type: 'roleplay',
          title: '情境',
          description: '進入「$roleplay」情境，把本章內容用在真實對話。',
          action: 'roleplay',
        ),
        const LearningCourseLesson(
          type: 'quiz',
          title: '小測驗',
          description: '用自適應每日訓練確認這一章是否真的掌握。',
          action: 'daily',
        ),
      ],
    );
  }
}
