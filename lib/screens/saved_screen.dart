import 'package:flutter/material.dart';

import '../models/learning_item.dart';
import 'learning_card_screen.dart';

class SavedScreen extends StatefulWidget {
  static const categories = <String>[
    LearningItem.uncategorized,
    '工作',
    '生活',
    'English',
    'Tagalog',
  ];

  final List<LearningItem> items;
  final bool isLoading;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(String id, String category) onCategoryChanged;

  const SavedScreen({
    super.key,
    required this.items,
    required this.isLoading,
    required this.onDelete,
    required this.onCategoryChanged,
  });

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  static const _allCategory = '全部';

  final _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = _allCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$month/$day';
  }

  List<LearningItem> get _filteredItems {
    final query = _query.trim().toLowerCase();

    return widget.items.where((item) {
      final matchesCategory = _selectedCategory == _allCategory ||
          item.category == _selectedCategory;
      final analysis = item.analysis;
      final searchable = [
        item.text,
        item.category,
        if (analysis != null) ...[
          analysis.chinese,
          analysis.english,
          analysis.tagalog,
          analysis.tone,
          ...analysis.learningPoints.expand(
            (point) => [point.title, point.explanation],
          ),
        ],
      ].join(' ').toLowerCase();
      final matchesQuery = query.isEmpty || searchable.contains(query);
      return matchesCategory && matchesQuery;
    }).toList(growable: false);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  Future<void> _chooseCategory(
    BuildContext context,
    LearningItem item,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('選擇分類'),
          children: [
            for (final category in SavedScreen.categories)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(category),
                child: Row(
                  children: [
                    Icon(
                      item.category == category
                          ? Icons.check_circle_rounded
                          : Icons.label_outline_rounded,
                    ),
                    const SizedBox(width: 12),
                    Text(category),
                  ],
                ),
              ),
          ],
        );
      },
    );

    if (selected == null || selected == item.category || !context.mounted) {
      return;
    }

    await widget.onCategoryChanged(item.id, selected);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已分類為「$selected」。')),
    );
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

    await widget.onDelete(item.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已刪除收藏。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;
    final hasQuery = _query.trim().isNotEmpty;
    final hasFilter = _selectedCategory != _allCategory;

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
              if (!widget.isLoading)
                Chip(
                  avatar: const Icon(Icons.bookmark_rounded, size: 18),
                  label: Text(
                    hasQuery || hasFilter
                        ? '${filteredItems.length}/${widget.items.length} 句'
                        : '${widget.items.length} 句',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('把真實遇到的句子變成自己的教材。'),
          const SizedBox(height: 16),
          if (!widget.isLoading && widget.items.isNotEmpty) ...[
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜尋收藏，例如 want、reply...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: hasQuery
                    ? IconButton(
                        tooltip: '清除搜尋',
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final category in [
                    _allCategory,
                    ...SavedScreen.categories,
                  ]) ...[
                    FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.items.isEmpty)
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
          else if (filteredItems.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 44,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '找不到符合的收藏',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasQuery
                          ? '沒有找到「${_query.trim()}」，換個關鍵字或分類試試看。'
                          : '這個分類目前還沒有收藏句子。',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            for (final item in filteredItems) ...[
              Card(
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LearningCardScreen(item: item),
                      ),
                    );
                  },
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('收藏於 ${_formatDate(item.createdAt)}'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(
                                Icons.label_outline_rounded,
                                size: 18,
                              ),
                              label: Text(item.category),
                              onPressed: () => _chooseCategory(context, item),
                            ),
                            if (item.hasAnalysis)
                              const Chip(
                                avatar: Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                ),
                                label: Text('完整學習卡'),
                              ),
                          ],
                        ),
                      ],
                    ),
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
