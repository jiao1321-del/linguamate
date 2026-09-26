import 'package:flutter/material.dart';

import '../models/learning_item.dart';

class ReviewScreen extends StatefulWidget {
  final List<LearningItem> items;
  final Future<void> Function(String id, bool remembered) onReviewResult;

  const ReviewScreen({
    super.key,
    required this.items,
    required this.onReviewResult,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late List<LearningItem> _remaining;
  late int _targetCount;

  bool _showDetails = false;
  bool _isSavingReview = false;
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
    _isSavingReview = false;
    _rememberedCount = 0;
    _againCount = 0;
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$month/$day';
  }

  Future<void> _remember() async {
    if (_remaining.isEmpty || _isSavingReview) return;
    final current = _remaining.first;

    setState(() => _isSavingReview = true);

    try {
      await widget.onReviewResult(current.id, true);
      if (!mounted) return;

      setState(() {
        _remaining.removeAt(0);
        _rememberedCount += 1;
        _showDetails = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('複習進度儲存失敗，請再試一次。')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingReview = false);
      }
    }
  }

  Future<void> _reviewAgain() async {
    if (_remaining.isEmpty || _isSavingReview) return;
    final current = _remaining.first;

    setState(() => _isSavingReview = true);

    try {
      await widget.onReviewResult(current.id, false);
      if (!mounted) return;

      setState(() {
        final item = _remaining.removeAt(0);
        _remaining.add(item);
        _againCount += 1;
        _showDetails = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('複習進度儲存失敗，請再試一次。')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingReview = false);
      }
    }
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
                  Icons.event_available_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '今天沒有到期句子',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '完成得很漂亮。句子會在排定的日期再次出現。',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('回到首頁'),
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
                  '完成 $_targetCount 句，過程中有 $_againCount 次選擇再複習。\n'
                  '按「記得」的句子已自動排入下一次複習。',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('現在再跑一輪'),
                ),
                const SizedBox(height: 10),
                FilledButton(
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
                    onTap: _isSavingReview
                        ? null
                        : () {
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
                                        const SizedBox(height: 6),
                                        Text(
                                          '已複習 ${current.reviewCount} 次 · 階段 ${current.reviewLevel}',
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
                      onPressed: _isSavingReview ? null : _reviewAgain,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('再複習'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSavingReview ? null : _remember,
                      icon: _isSavingReview
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(_isSavingReview ? '儲存中...' : '記得'),
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
