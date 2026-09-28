import 'package:flutter/material.dart';

import '../models/learning_item.dart';
import '../models/learning_ability.dart';
import '../models/mistake_record.dart';
import '../models/weakness_record.dart';

class ProfileScreen extends StatelessWidget {
  final List<LearningItem> items;
  final bool isLoading;
  final List<WeaknessRecord> weaknesses;
  final bool isLoadingWeaknesses;
  final List<MistakeRecord> mistakes;
  final LearningAbilityReport abilityReport;
  final VoidCallback? onPracticeMistakes;
  final VoidCallback? onOpenProgress;
  final VoidCallback? onOpenGrowth;
  final VoidCallback? onOpenAdaptive;
  final VoidCallback? onOpenSpeaking;
  final VoidCallback? onOpenCourse;
  final VoidCallback? onOpenCloud;
  final VoidCallback onOpenBackup;

  const ProfileScreen({
    super.key,
    required this.items,
    required this.isLoading,
    this.weaknesses = const <WeaknessRecord>[],
    this.isLoadingWeaknesses = false,
    this.mistakes = const <MistakeRecord>[],
    this.abilityReport = const LearningAbilityReport(
      records: <LearningAbilityRecord>[],
    ),
    this.onPracticeMistakes,
    this.onOpenProgress,
    this.onOpenGrowth,
    this.onOpenAdaptive,
    this.onOpenSpeaking,
    this.onOpenCourse,
    this.onOpenCloud,
    required this.onOpenBackup,
  });

  int get _categorizedCount => items
      .where((item) => item.category != LearningItem.uncategorized)
      .length;

  int get _uncategorizedCount => items.length - _categorizedCount;

  int get _dueCount {
    final now = DateTime.now();
    return items.where((item) => item.isDue(now)).length;
  }

  int get _reviewedCount =>
      items.where((item) => item.reviewCount > 0).length;

  int get _stableCount =>
      items.where((item) => item.reviewLevel >= 3).length;

  String _value(int value) => isLoading ? '—' : value.toString();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          Text(
            '我的學習',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 20),
          const Card(
            child: ListTile(
              contentPadding: EdgeInsets.all(18),
              leading: CircleAvatar(
                radius: 28,
                child: Icon(Icons.person),
              ),
              title: Text(
                'Language Learner',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('English · Tagalog / Taglish'),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bookmark_outline_rounded),
                  title: const Text('已收藏句子'),
                  trailing: Text(
                    _value(items.length),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.label_outline_rounded),
                  title: const Text('已分類'),
                  trailing: Text(
                    _value(_categorizedCount),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.inbox_outlined),
                  title: const Text('未分類'),
                  trailing: Text(
                    _value(_uncategorizedCount),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text('目前待複習'),
                  trailing: Text(
                    _value(_dueCount),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.fact_check_outlined),
                  title: const Text('已開始複習'),
                  trailing: Text(
                    _value(_reviewedCount),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.psychology_alt_outlined),
                  title: const Text('穩定記憶'),
                  subtitle: const Text('已達複習階段 3 以上'),
                  trailing: Text(
                    _value(_stableCount),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            key: const ValueKey('progress-center-entry'),
            child: ListTile(
              onTap: onOpenProgress,
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(Icons.insights_outlined),
              title: const Text(
                '學習進度中心',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                '連續天數、近 7 天題數、能力分布與近期訓練紀錄',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            key: const ValueKey('growth-center-entry'),
            child: ListTile(
              onTap: onOpenGrowth,
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(Icons.rocket_launch_outlined),
              title: const Text(
                '成長中心',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                '每日目標、XP 等級、成就徽章、近 7 天週報與 28 天學習日曆',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            key: const ValueKey('adaptive-learning-entry'),
            child: ListTile(
              onTap: onOpenAdaptive,
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(Icons.hub_outlined),
              title: const Text(
                'Shili 自適應學習',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                '智慧複習、主動教練、口說評分、7 天課程、學習記憶與個人難度',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            key: const ValueKey('speaking-progress-entry'),
            child: ListTile(
              onTap: onOpenSpeaking,
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(Icons.record_voice_over_outlined),
              title: const Text(
                '口說教練 2.0',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                '查看最近 7 次口說分數、完整度、流暢度與漏字紀錄',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            key: const ValueKey('course-plan-entry'),
            child: ListTile(
              onTap: onOpenCourse,
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(Icons.auto_stories_outlined),
              title: const Text(
                'AI 個人課程 2.0',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                '依弱點生成章節；完成素材、句型、口說、情境與小測驗後解鎖下一章',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            key: const ValueKey('cloud-sync-entry'),
            child: ListTile(
              onTap: onOpenCloud,
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(Icons.cloud_sync_outlined),
              title: const Text(
                'LinguaMate Cloud',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text(
                '帳號登入與雲端同步：收藏、錯題、能力、口說、課程與 Shili 對話',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            key: const ValueKey('learning-ability-card'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '學習能力',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      if (abilityReport.totalAttempts > 0)
                        Text(
                          '答對率 ${abilityReport.overallAccuracy}%',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AbilitySummaryBox(
                          label: '已掌握',
                          value: abilityReport.masteredCount,
                          icon: Icons.verified_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AbilitySummaryBox(
                          label: '學習中',
                          value: abilityReport.learningCount,
                          icon: Icons.auto_graph_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AbilitySummaryBox(
                          label: '待加強',
                          value: abilityReport.needsWorkCount,
                          icon: Icons.priority_high_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (abilityReport.records.isEmpty)
                    const Text(
                      '完成每日訓練後，這裡會開始統計答對率、錯誤次數與熟練度。',
                    )
                  else ...[
                    if (abilityReport.priorityLabel != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F5FC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '🎯 目前優先加強：${abilityReport.priorityLabel}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    const SizedBox(height: 10),
                    for (final ability in abilityReport.ranked.take(5)) ...[
                      _AbilityProgressRow(ability: ability),
                      if (ability != abilityReport.ranked.take(5).last)
                        const Divider(height: 16),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            key: const ValueKey('mistake-book-card'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '錯題本',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      Text(
                        '${mistakes.where((item) => item.isActive).length} 待加強',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (mistakes.where((item) => item.isActive).isEmpty)
                    const Text('目前沒有待加強內容，答錯的題目會自動收進這裡。')
                  else ...[
                    for (final mistake
                        in mistakes.where((item) => item.isActive).take(3))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: CircleAvatar(
                          child: Text(
                            mistake.wrongCount.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(
                          mistake.prompt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${mistake.title} · 錯 ${mistake.wrongCount} 次',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 6),
                    FilledButton.tonalIcon(
                      key: const ValueKey('practice-mistakes-button'),
                      onPressed: onPracticeMistakes,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('只練錯題'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '連續答對 3 次後會自動降低優先級。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF756B82),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.track_changes_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '常見弱點',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (isLoadingWeaknesses)
                    const LinearProgressIndicator()
                  else if (weaknesses.isEmpty)
                    const Text(
                      '和 Shili 對話後，常見修正會自動整理在這裡。',
                    )
                  else
                    for (final weakness in weaknesses.take(5)) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: CircleAvatar(
                          child: Text(
                            weakness.count.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(
                          weakness.category,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: weakness.explanation.trim().isEmpty
                            ? null
                            : Text(
                                weakness.explanation,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: Text(
                          '${weakness.count} 次',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (weakness != weaknesses.take(5).last)
                        const Divider(height: 1),
                    ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              onTap: onOpenBackup,
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(Icons.backup_outlined),
              title: const Text(
                '備份與還原',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                '備份收藏、分類與 SRS 複習進度',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_graph_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'LinguaMate 現在會依你的複習結果安排下一次出現時間：1、3、7、14、30 天。按「再複習」會把該句重新排回優先複習。',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AbilitySummaryBox extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _AbilitySummaryBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AbilityProgressRow extends StatelessWidget {
  final LearningAbilityRecord ability;

  const _AbilityProgressRow({
    required this.ability,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = (ability.accuracy * 100).round();
    final recent = ability.lastResultCorrect == null
        ? ''
        : ability.lastResultCorrect!
            ? ' · 最近答對'
            : ' · 最近答錯';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ability.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ability.statusLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ability.score / 100,
          minHeight: 6,
          borderRadius: BorderRadius.circular(999),
        ),
        const SizedBox(height: 6),
        Text(
          '熟練度 ${ability.score}% · 答對率 $accuracy% · ${ability.attempts} 題 · 錯 ${ability.wrongCount} 次$recent',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF756B82),
              ),
        ),
      ],
    );
  }
}
