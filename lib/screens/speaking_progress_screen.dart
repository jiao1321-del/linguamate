import 'package:flutter/material.dart';

import '../models/speaking_attempt.dart';

class SpeakingProgressScreen extends StatelessWidget {
  final List<SpeakingAttempt> attempts;

  const SpeakingProgressScreen({
    super.key,
    required this.attempts,
  });

  int get _average {
    if (attempts.isEmpty) return 0;
    final recent = attempts.take(7).toList(growable: false);
    return (recent.fold<int>(0, (sum, item) => sum + item.score) /
            recent.length)
        .round();
  }

  @override
  Widget build(BuildContext context) {
    final recent = attempts.take(7).toList(growable: false).reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('口說教練 2.0')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Card(
            key: const ValueKey('speaking-progress-summary'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'V1.33 · 最近 7 次口說趨勢',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    attempts.isEmpty
                        ? '還沒有口說紀錄。到 Shili 頁面點「口說評分」開始建立基準。'
                        : '最近平均 $_average 分 · 已累積 ${attempts.length} 次',
                  ),
                  if (recent.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final attempt in recent)
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${attempt.score}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 70 * attempt.score / 100 + 8,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (attempts.isNotEmpty)
            for (final attempt in attempts.take(20))
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      '${attempt.score}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  title: Text(
                    attempt.target,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '你說：${attempt.transcript}\n完整度 ${attempt.completeness}% · 流暢度 ${attempt.fluency}%'
                    '${attempt.missingWords.isEmpty ? '' : ' · 漏字 ${attempt.missingWords.join('、')}'}',
                  ),
                  isThreeLine: true,
                ),
              ),
        ],
      ),
    );
  }
}
