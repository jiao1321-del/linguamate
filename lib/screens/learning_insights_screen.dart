import 'package:flutter/material.dart';

import '../models/learning_insights.dart';

class LearningInsightsScreen extends StatelessWidget {
  final LearningInsightsSnapshot snapshot;

  const LearningInsightsScreen({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Intelligence')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Card(
            key: const ValueKey('v145-learning-intelligence'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'V1.45 · 30 天學習分析',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: '7 天題數',
                          value: '${snapshot.tasks7}',
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: '30 天題數',
                          value: '${snapshot.tasks30}',
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: '估計分鐘',
                          value: '${snapshot.estimatedMinutes30}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: '7 天答對率',
                          value: '${snapshot.accuracy7}%',
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: '30 天答對率',
                          value: '${snapshot.accuracy30}%',
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: '口說平均',
                          value: snapshot.speakingAverage == 0
                              ? '—'
                              : '${snapshot.speakingAverage}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.trending_up_rounded),
              title: const Text('最快進步'),
              subtitle: Text(snapshot.fastestImproving),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.hourglass_bottom_rounded),
              title: const Text('最久沒練'),
              subtitle: Text(snapshot.staleAbility),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline_rounded),
              title: const Text('最高優先錯題'),
              subtitle: Text(snapshot.topMistake),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shili 本週報告',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.weeklyReport),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '下週最值得做的 3 件事',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < snapshot.nextActions.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(snapshot.nextActions[i]),
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

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
