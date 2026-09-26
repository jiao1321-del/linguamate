import 'package:flutter/material.dart';

import '../models/learning_item.dart';
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

  @override
  Widget build(BuildContext context) {
    final analysis = item.analysis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('完整學習卡'),
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
                          avatar: const Icon(Icons.label_outline_rounded, size: 18),
                          label: Text(item.category),
                        ),
                        Chip(
                          avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                          label: Text(_formatDate(item.createdAt)),
                        ),
                        Chip(
                          avatar: const Icon(Icons.psychology_alt_outlined, size: 18),
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
            if (analysis != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LanguageAnalysisDetails(
                    analysis: analysis,
                  ),
                ),
              )
            else
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
