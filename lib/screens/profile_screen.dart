import 'package:flutter/material.dart';

import '../models/learning_item.dart';
import '../models/mistake_record.dart';
import '../models/weakness_record.dart';

class ProfileScreen extends StatelessWidget {
  final List<LearningItem> items;
  final bool isLoading;
  final List<WeaknessRecord> weaknesses;
  final bool isLoadingWeaknesses;
  final List<MistakeRecord> mistakes;
  final VoidCallback? onPracticeMistakes;
  final VoidCallback onOpenBackup;

  const ProfileScreen({
    super.key,
    required this.items,
    required this.isLoading,
    this.weaknesses = const <WeaknessRecord>[],
    this.isLoadingWeaknesses = false,
    this.mistakes = const <MistakeRecord>[],
    this.onPracticeMistakes,
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
