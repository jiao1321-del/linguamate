import 'package:flutter/material.dart';

import '../models/learning_item.dart';

class ReviewScreen extends StatefulWidget {
  final List<LearningItem> items;

  const ReviewScreen({
    super.key,
    required this.items,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late List<LearningItem> _remaining;
  late int _targetCount;

  bool _showDetails = false;
  int _rememberedCount = 0;
  int _againCount = 0;

  @override
  void initState() {
    super.initState();
    _resetSession();
  }

  void _resetSession() {
    _remaining = widget.items.take(10).toList(growable: true);
    _targetCount = _remaining.length;
    _showDetails = false;
    _rememberedCount = 0;
    _againCount = 0;
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$month/$day';
  }

  void _remember() {
    if (_remaining.isEmpty) return;

    setState(() {
      _remaining.removeAt(0);
      _rememberedCount += 1;
      _showDetails = false;
    });
  }

  void _reviewAgain() {
    if (_remaining.isEmpty) return;

    setState(() {
      final current = _remaining.removeAt(0);
      _remaining.add(current);
      _againCount += 1;
      _showDetails = false;
    });
  }

  void _restart() {
    setState(_resetSession);
  }

  @override
  Widget build(BuildContext context) {
    if (_targetCount == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('今日複習')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark_add_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '還沒有可以複習的句子',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '先到「學習」頁收藏一句，之後就能在這裡開始複習。',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_remaining.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('今日複習')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.celebration_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  '今日複習完成 🎉',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '完成 $_targetCount 句，過程中有 $_againCount 次選擇再複習。',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('再複習一次'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('回到首頁'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final current = _remaining.first;
    final progress =
        _targetCount == 0 ? 0.0 : _rememberedCount / _targetCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日複習'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_rememberedCount / $_targetCount',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '剩餘 ${_remaining.length} 句',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showDetails = !_showDetails);
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 520),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 34,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showDetails
                                  ? Icons.visibility_rounded
                                  : Icons.touch_app_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              current.text,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.35,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _showDetails
                                  ? Column(
                                      key: const ValueKey('details'),
                                      children: [
                                        Chip(
                                          avatar: const Icon(
                                            Icons.label_outline,
                                            size: 18,
                                          ),
                                          label: Text(current.category),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '收藏於 ${_formatDate(current.createdAt)}',
                                        ),
                                      ],
                                    )
                                  : Text(
                                      '點一下卡片查看提示',
                                      key: const ValueKey('hint'),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reviewAgain,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('再複習'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _remember,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('記得'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
