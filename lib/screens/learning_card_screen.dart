import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/learning_item.dart';
import '../widgets/gilded_card_icon.dart';
import '../widgets/language_analysis_details.dart';

class LearningCardScreen extends StatelessWidget {
  final LearningItem item;

  const LearningCardScreen({
    super.key,
    required this.item,
  });

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}/$month/$day';
  }

  Future<void> _copyText(
    BuildContext context,
    String label,
    String text,
  ) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: normalized));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已複製$label')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysis = item.analysis;

    return Scaffold(
      appBar: AppBar(
        title: const Tooltip(
          message: 'AI 學習卡',
          child: GildedCardIcon(
            width: 24,
            height: 31,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.format_quote_rounded),
                        const SizedBox(width: 8),
                        Text(
                          '原句',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      item.text,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(
                            Icons.label_outline_rounded,
                            size: 18,
                          ),
                          label: Text(item.category),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                          ),
                          label: Text(_formatDate(item.createdAt)),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.psychology_alt_outlined,
                            size: 18,
                          ),
                          label: Text(
                            '複習 ${item.reviewCount} 次 · 階段 ${item.reviewLevel}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (analysis != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const GildedCardIcon(
                            width: 24,
                            height: 31,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '快速操作',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _copyText(
                              context,
                              '中文',
                              analysis.chinese,
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('複製中文'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _copyText(
                              context,
                              ' English',
                              analysis.english,
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('複製 English'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _copyText(
                              context,
                              ' Tagalog',
                              analysis.tagalog,
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('複製 Tagalog'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LanguageAnalysisDetails(
                    analysis: analysis,
                  ),
                ),
              ),
            ] else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 38,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '這是 V1.1 以前收藏的舊句子',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '舊資料會完整保留，但當時沒有保存 AI 三語分析。',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
