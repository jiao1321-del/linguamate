import 'package:flutter/material.dart';

import '../models/learning_item.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  final List<LearningItem> items;
  final bool isLoading;
  final VoidCallback onStartLearning;

  const HomeScreen({
    super.key,
    required this.items,
    required this.isLoading,
    required this.onStartLearning,
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

  int get _categorizedCount => items
      .where((item) => item.category != LearningItem.uncategorized)
      .length;

  int get _uncategorizedCount => items.length - _categorizedCount;

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
                label: '今日新增',
                value: _value(_todayCount),
                icon: Icons.add_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatCard(
                label: '已分類',
                value: _value(_categorizedCount),
                icon: Icons.label_outline_rounded,
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
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('1')),
                    title: Text('新增 1 個今天真的會用到的句子'),
                    subtitle: Text('把工作或生活中的句子放進 LinguaMate'),
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
                          : '今天可以專心新增或複習句子',
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: onStartLearning,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('開始今日學習'),
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
