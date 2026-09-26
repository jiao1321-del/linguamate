import 'package:flutter/material.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('I will reply to you later.', '我晚點回覆你。', '熟悉'),
      ('I mainly use it for my studies.', '我主要拿它來學習。', '學習中'),
      ('Are you free tomorrow?', '你明天有空嗎？', '新句子'),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          Text(
            '我的收藏',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          const Text('把真實遇到的句子變成自己的教材。'),
          const SizedBox(height: 20),
          for (final item in items) ...[
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                title: Text(
                  item.$1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(item.$2),
                ),
                trailing: Chip(label: Text(item.$3)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
