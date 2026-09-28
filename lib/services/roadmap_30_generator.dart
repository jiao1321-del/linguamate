import '../models/roadmap_30.dart';

class Roadmap30Generator {
  const Roadmap30Generator._();

  static const goals = <String>[
    '日常英文',
    '工作英文',
    '旅遊英文',
    'Tagalog 日常',
    'Taglish',
    '面試英文',
    '會議／報告英文',
  ];

  static Roadmap30Plan generate({
    required String goal,
    required String priority,
    required String weakness,
  }) {
    final safeGoal = goals.contains(goal) ? goal : goals.first;
    final days = <Roadmap30Day>[];

    for (var day = 1; day <= 30; day++) {
      final week = ((day - 1) ~/ 7) + 1;
      final inWeek = ((day - 1) % 7) + 1;
      final checkpoint = day == 7 || day == 14 || day == 21 || day == 30;

      final template = switch (inWeek) {
        1 => ('智慧複習', priority, 'daily'),
        2 => ('弱點修復', weakness, 'mistakes'),
        3 => ('口說轉化', safeGoal, 'speaking'),
        4 => ('素材擴充', safeGoal, 'ai'),
        5 => ('句型整合', priority, 'daily'),
        6 => ('情境實戰', safeGoal, 'roleplay'),
        _ => ('週檢查點', '本週綜合', 'daily'),
      };

      days.add(
        Roadmap30Day(
          day: day,
          week: week,
          title: checkpoint ? 'Checkpoint · ${template.$1}' : template.$1,
          focus: template.$2,
          action: template.$3,
          checkpoint: checkpoint,
        ),
      );
    }

    return Roadmap30Plan(
      goal: safeGoal,
      title: '30 天 · $safeGoal',
      summary:
          '以「$priority」為優先能力、「$weakness」為補強重點，每週重新混合複習、口說與情境。',
      days: days,
    );
  }
}
