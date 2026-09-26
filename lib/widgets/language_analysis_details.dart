import 'package:flutter/material.dart';

import '../models/language_analysis.dart';

class LanguageAnalysisDetails extends StatelessWidget {
  final LanguageAnalysis analysis;
  final bool compact;

  const LanguageAnalysisDetails({
    super.key,
    required this.analysis,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: '🇹🇼 中文',
          content: analysis.chinese,
          compact: compact,
        ),
        _Section(
          title: '🇺🇸 English',
          content: analysis.english,
          compact: compact,
        ),
        _Section(
          title: '🇵🇭 Tagalog / Taglish',
          content: analysis.tagalog,
          compact: compact,
        ),
        _Section(
          title: '💬 語氣與使用情境',
          content: analysis.tone,
          compact: compact,
        ),
        if (analysis.learningPoints.isNotEmpty) ...[
          SizedBox(height: compact ? 10 : 14),
          Text(
            '✨ 學習重點',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          SizedBox(height: compact ? 8 : 10),
          for (var i = 0; i < analysis.learningPoints.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: analysis.learningPoints[i].title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (analysis.learningPoints[i].explanation.isNotEmpty)
                          TextSpan(
                            text:
                                ' — ${analysis.learningPoints[i].explanation}',
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (i != analysis.learningPoints.length - 1)
              SizedBox(height: compact ? 7 : 9),
          ],
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final bool compact;

  const _Section({
    required this.title,
    required this.content,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          SelectableText(
            content,
            style: TextStyle(
              height: 1.4,
              fontSize: compact ? 14 : null,
            ),
          ),
        ],
      ),
    );
  }
}
