import 'package:flutter/material.dart';

import '../models/adaptive_learning.dart';

class AdaptiveLearningScreen extends StatelessWidget {
  final AdaptiveLearningSnapshot snapshot;
  final ValueChanged<String>? onAction;

  const AdaptiveLearningScreen({
    super.key,
    required this.snapshot,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shili 自適應學習')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          _VersionCard(
            key: const ValueKey('v125-smart-review'),
            icon: Icons.history_toggle_off_rounded,
            title: 'V1.25 · 智慧複習 2.0',
            body: snapshot.smartReviewReason,
            footer: '目前到期：${snapshot.dueReviewCount} 個',
          ),
          const SizedBox(height: 12),
          _VersionCard(
            key: const ValueKey('v126-proactive-coach'),
            icon: Icons.auto_awesome_rounded,
            title: 'V1.26 · Shili 主動教練',
            body: snapshot.coachMessage,
            actionLabel: '照 Shili 建議開始',
            onPressed: () => onAction?.call(snapshot.recommendedAction),
          ),
          const SizedBox(height: 12),
          _VersionCard(
            key: const ValueKey('v127-speaking-score'),
            icon: Icons.record_voice_over_outlined,
            title: 'V1.27 · 口說評分',
            body: snapshot.speakingAttempts == 0
                ? '還沒有口說評分紀錄。到 Shili 頁面可以用語音辨識結果估算完整度、流暢度與漏字。'
                : '已完成 ${snapshot.speakingAttempts} 次口說評分，通過率 ${snapshot.speakingAccuracy}%。',
            actionLabel: '到 Shili 練口說',
            onPressed: () => onAction?.call('speaking'),
          ),
          const SizedBox(height: 12),
          Card(
            key: const ValueKey('v128-seven-day-course'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.view_week_outlined),
                      SizedBox(width: 10),
                      Text(
                        'V1.28 · AI 7 天個人課程',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('每天重新依最新結果計算，所以課程不是固定死的。'),
                  const SizedBox(height: 12),
                  for (final day in snapshot.course)
                    ListTile(
                      key: ValueKey('adaptive-course-day-${day.day}'),
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text('${day.day}')),
                      title: Text(
                        '${day.title} · ${day.focus}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(day.reason),
                      trailing: IconButton(
                        tooltip: '開始',
                        onPressed: () => onAction?.call(day.action),
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            key: const ValueKey('v129-learning-memory'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_alt_outlined),
                      SizedBox(width: 10),
                      Text(
                        'V1.29 · Shili 學習記憶',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(snapshot.memory.summary),
                  if (snapshot.memory.masteredSkills.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final skill in snapshot.memory.masteredSkills)
                          Chip(label: Text('✓ $skill')),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '這份摘要會提供給 Shili，讓對話避免一直重教已掌握內容。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            key: const ValueKey('v130-adaptive-engine'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hub_outlined),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'V1.30 · 自適應學習引擎 1.0',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Chip(label: Text(snapshot.stage)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '個人難度：Lv.${snapshot.difficulty}/10 · ${snapshot.difficultyLabel}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.dailyPlanReason),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: snapshot.difficulty / 10,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '訓練中若連續答錯，系統會把同類型題目提前，立即切成補強節奏；已掌握能力則降低出題優先度。',
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

class _VersionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? footer;
  final String? actionLabel;
  final VoidCallback? onPressed;

  const _VersionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.footer,
    this.actionLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body),
            if (footer != null) ...[
              const SizedBox(height: 8),
              Text(
                footer!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
