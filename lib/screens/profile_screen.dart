import 'package:flutter/material.dart';

import '../models/learning_item.dart';

class ProfileScreen extends StatelessWidget {
  final List<LearningItem> items;
  final bool isLoading;

  const ProfileScreen({
    super.key,
    required this.items,
    required this.isLoading,
  });

  int get _categorizedCount => items
      .where((item) => item.category != LearningItem.uncategorized)
      .length;

  int get _uncategorizedCount => items.length - _categorizedCount;

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
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.insights_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '這裡現在顯示的都是你的真實收藏資料。之後加入複習與學習進度後，這一頁也會跟著變成完整的學習統計。',
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
