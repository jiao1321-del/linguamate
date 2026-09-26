import 'package:flutter/material.dart';

import '../models/learning_item.dart';

class SavedScreen extends StatelessWidget {
  final List<LearningItem> items;
  final bool isLoading;
  final Future<void> Function(String id) onDelete;

  const SavedScreen({
    super.key,
    required this.items,
    required this.isLoading,
    required this.onDelete,
  });

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$month/$day';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LearningItem item,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('刪除收藏？'),
          content: Text(
            '確定要刪除這句嗎？\n\n${item.text}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('刪除'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) return;

    await onDelete(item.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已刪除收藏。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '我的收藏',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (!isLoading)
                Chip(
                  avatar: const Icon(Icons.bookmark_rounded, size: 18),
                  label: Text('${items.length} 句'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('把真實遇到的句子變成自己的教材。'),
          const SizedBox(height: 20),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '還沒有收藏句子',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '到「學習」頁加入第一句，之後重新開啟 LinguaMate 也會保留。',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            for (final item in items) ...[
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  leading: const CircleAvatar(
                    child: Icon(Icons.bookmark_rounded),
                  ),
                  title: Text(
                    item.text,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text('收藏於 ${_formatDate(item.createdAt)}'),
                  ),
                  trailing: IconButton(
                    tooltip: '刪除收藏',
                    onPressed: () => _confirmDelete(context, item),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}
