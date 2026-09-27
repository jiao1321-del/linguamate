import 'package:flutter/material.dart';

import '../models/learning_item.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  final List<LearningItem> items;
  final bool isLoading;
  final int dailyTrainingTaskCount;
  final int dailyTrainingEstimatedMinutes;
  final bool dailyTrainingCompleted;
  final String? dailyTrainingFocusLabel;
  final VoidCallback? onStartDailyTraining;
  final VoidCallback onStartReview;

  const HomeScreen({
    super.key,
    required this.items,
    required this.isLoading,
    this.dailyTrainingTaskCount = 0,
    this.dailyTrainingEstimatedMinutes = 0,
    this.dailyTrainingCompleted = false,
    this.dailyTrainingFocusLabel,
    this.onStartDailyTraining,
    required this.onStartReview,
  });

  int get _todayCount {
    final now = DateTime.now();
    return items.where((item) {
      final date = item.createdAt.toLocal();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  int get _dueCount {
    final now = DateTime.now();
    return items.where((item) => item.isDue(now)).length;
  }

  int get _uncategorizedCount =>
      items.where((item) => item.category == LearningItem.uncategorized).length;

  String _value(int value) => isLoading ? '—' : value.toString();

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$month/$day';
  }

  @override
  Widget build(BuildContext context) {
    final recentItems = items.take(3).toList(growable: false);
    final reviewCount = _dueCount > 10 ? 10 : _dueCount;
    final hasDueItems = _dueCount > 0;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          Text(
            'LinguaMate',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          const Text('今天也學一點真正用得到的語言 ✨'),
          const SizedBox(height: 24),
          Row(
            children: [
              StatCard(
                label: '收藏總數',
                value: _value(items.length),
                icon: Icons.bookmark_outline_rounded,
              ),
              const SizedBox(width: 12),
              StatCard(
                label: '待複習',
                value: _value(_dueCount),
                icon: Icons.history_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatCard(
                label: '今日新增',
                value: _value(_todayCount),
                icon: Icons.add_circle_outline,
              ),
              const SizedBox(width: 12),
              StatCard(
                label: '未分類',
                value: _value(_uncategorizedCount),
                icon: Icons.inbox_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            key: const ValueKey('daily-training-card'),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '今日訓練',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      if (dailyTrainingCompleted)
                        const Icon(Icons.check_circle_rounded),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dailyTrainingTaskCount == 0
                        ? '先和 Shili 聊幾句或建立學習卡，系統就會自動安排。'
                        : '$dailyTrainingTaskCount 題 · 約 $dailyTrainingEstimatedMinutes 分鐘',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dailyTrainingCompleted
                        ? '今天已完成；想加強的話可以再練一次。'
                        : dailyTrainingFocusLabel?.trim().isNotEmpty == true
                            ? '今日優先：$dailyTrainingFocusLabel · 依熟練度自動調整題目順序。'
                            : '依你的單字、文法、常見弱點與 SRS 到期內容自動安排。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF756B82),
                        ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    key: const ValueKey('start-daily-training'),
                    onPressed:
                        dailyTrainingTaskCount > 0 ? onStartDailyTraining : null,
                    icon: Icon(
                      dailyTrainingCompleted
                          ? Icons.replay_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      dailyTrainingCompleted ? '再練一次' : '開始今日訓練',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日任務',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Text('1')),
                    title: Text(
                      items.isEmpty
                          ? '新增 1 個今天真的會用到的句子'
                          : hasDueItems
                              ? '複習 $reviewCount 個到期句子'
                              : '今天的複習已完成',
                    ),
                    subtitle: Text(
                      items.isEmpty
                          ? '先建立第一張屬於你的複習卡'
                          : hasDueItems
                              ? '系統會依你的記憶狀況安排下次複習'
                              : '下一批句子會在排定日期再次出現',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Text('2')),
                    title: Text(
                      _uncategorizedCount > 0
                          ? '整理 $_uncategorizedCount 個未分類收藏'
                          : '收藏分類已整理完成',
                    ),
                    subtitle: Text(
                      _uncategorizedCount > 0
                          ? '幫句子加上工作、生活或語言分類'
                          : '分類完成，可以專心複習',
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: isLoading || (!hasDueItems && items.isNotEmpty)
                        ? null
                        : onStartReview,
                    icon: Icon(
                      items.isEmpty
                          ? Icons.add_rounded
                          : hasDueItems
                              ? Icons.play_arrow_rounded
                              : Icons.check_circle_outline_rounded,
                    ),
                    label: Text(
                      isLoading
                          ? '準備中...'
                          : items.isEmpty
                              ? '新增第一句'
                              : hasDueItems
                                  ? '開始今日複習'
                                  : '今日複習完成',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '最近收藏',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            )
          else if (recentItems.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 42,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '還沒有收藏句子',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '從「學習」頁加入第一句，首頁就會顯示你的真實學習紀錄。',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            for (final item in recentItems) ...[
              _SentenceCard(
                source: item.text,
                category: item.category,
                date: _formatDate(item.createdAt),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _SentenceCard extends StatelessWidget {
  final String source;
  final String category;
  final String date;

  const _SentenceCard({
    required this.source,
    required this.category,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        title: Text(
          source,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('收藏於 $date'),
        ),
        trailing: Chip(label: Text(category)),
      ),
    );
  }
}
