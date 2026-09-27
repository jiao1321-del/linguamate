import 'package:flutter/material.dart';

import '../models/learning_progress.dart';

class ProgressCenterScreen extends StatelessWidget {
  final LearningProgressReport report;

  const ProgressCenterScreen({
    super.key,
    required this.report,
  });

  String _typeLabel(String type) => switch (type) {
        'vocabulary' => '單字',
        'grammar' => '文法',
        'weakness' => '弱點',
        'review' => 'SRS',
        _ => type,
      };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final recent = report.latestPerDay.take(7).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('學習進度中心')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              '你的學習趨勢',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            const Text('把每天的練習累積成看得見的進步。'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _ProgressStat(
                    label: '連續學習',
                    value: '${report.streakAt(now)} 天',
                    icon: Icons.local_fire_department_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProgressStat(
                    label: '總答對率',
                    value: '${report.overallAccuracy}%',
                    icon: Icons.insights_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ProgressStat(
                    label: '近 7 天',
                    value: '${report.last7DaysTasks(now)} 題',
                    icon: Icons.calendar_view_week_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProgressStat(
                    label: '已掌握',
                    value: '${report.abilityReport.masteredCount} 項',
                    icon: Icons.verified_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              key: const ValueKey('progress-skill-card'),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '能力分布',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (report.typeTotals.isEmpty)
                      const Text('完成幾次今日訓練後，就會開始看到各能力趨勢。')
                    else
                      for (final type in const [
                        'vocabulary',
                        'grammar',
                        'weakness',
                        'review',
                      ])
                        if ((report.typeTotals[type] ?? 0) > 0) ...[
                          Row(
                            children: [
                              Expanded(child: Text(_typeLabel(type))),
                              Text(
                                '${report.typeAccuracy(type)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: report.typeAccuracy(type) / 100,
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          const SizedBox(height: 12),
                        ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              key: const ValueKey('progress-recent-card'),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最近 7 次訓練',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (recent.isEmpty)
                      const Text('還沒有訓練紀錄。今天完成第一組就會出現在這裡。')
                    else
                      for (final item in recent)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(
                              '${(item.accuracy * 100).round()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(item.dateKey),
                          subtitle: Text(
                            '${item.correctTasks}/${item.totalTasks} 題答對',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: const Icon(Icons.track_changes_outlined),
                title: const Text(
                  '目前需要加強',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  report.abilityReport.priorityLabel == null
                      ? '目前沒有明顯弱點，繼續維持。'
                      : '優先補強：${report.abilityReport.priorityLabel}',
                ),
                trailing: Text(
                  '${report.activeMistakeCount} 錯題',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF756B82),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
