import 'package:flutter/material.dart';

import '../models/adaptive_learning.dart';
import '../models/speaking_attempt.dart';
import '../services/adaptive_learning_engine.dart';
import '../services/speech_coach_service.dart';

class SpeakingProgressScreen extends StatefulWidget {
  final List<SpeakingAttempt> attempts;
  final SpeechCoachService? speechService;

  const SpeakingProgressScreen({
    super.key,
    required this.attempts,
    this.speechService,
  });

  @override
  State<SpeakingProgressScreen> createState() => _SpeakingProgressScreenState();
}

class _SpeakingProgressScreenState extends State<SpeakingProgressScreen> {
  late final SpeechCoachService _speech;

  @override
  void initState() {
    super.initState();
    _speech = widget.speechService ?? createSpeechCoachService();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  int get _average {
    if (widget.attempts.isEmpty) return 0;
    final recent = widget.attempts.take(7).toList(growable: false);
    return (recent.fold<int>(0, (sum, item) => sum + item.score) /
            recent.length)
        .round();
  }

  List<MapEntry<String, int>> get _topMissing {
    final counts = <String, int>{};
    for (final attempt in widget.attempts.take(30)) {
      for (final raw in attempt.missingWords) {
        final word = raw.trim().toLowerCase();
        if (word.isEmpty) continue;
        counts[word] = (counts[word] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        return count != 0 ? count : a.key.compareTo(b.key);
      });
    return entries.take(5).toList(growable: false);
  }

  Future<void> _speak(String text, {required bool slow}) {
    return _speech.speak(
      text: text,
      languageTag: 'en-US',
      rate: slow ? 0.34 : 0.48,
    );
  }

  @override
  Widget build(BuildContext context) {
    final attempts = widget.attempts;
    final recent = attempts.take(7).toList(growable: false).reversed.toList();
    final latest = attempts.isEmpty ? null : attempts.first;
    final latestAssessment = latest == null
        ? null
        : AdaptiveLearningEngine.assessPronunciation(
            target: latest.target,
            transcript: latest.transcript,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('口說教練 3.0')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Card(
            key: const ValueKey('v139-speaking-progress'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'V1.39 · 最近 7 次口說趨勢',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    attempts.isEmpty
                        ? '還沒有口說紀錄。到 Shili 頁面開始建立口說基準。'
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
          if (_topMissing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本期最常漏掉的 5 個詞',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in _topMissing)
                          ActionChip(
                            avatar: CircleAvatar(
                              child: Text('${entry.value}'),
                            ),
                            label: Text(entry.key),
                            onPressed: () => _speak(entry.key, slow: true),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (latestAssessment != null) ...[
            const SizedBox(height: 12),
            Card(
              key: const ValueKey('speaking-word-diff'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '逐字診斷 · 最新一次',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(latest!.target),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final token in latestAssessment.wordFeedback)
                          Chip(
                            avatar: Icon(
                              switch (token.status) {
                                SpeakingTokenStatus.correct =>
                                  Icons.check_rounded,
                                SpeakingTokenStatus.missing =>
                                  Icons.remove_circle_outline_rounded,
                                SpeakingTokenStatus.extra =>
                                  Icons.add_circle_outline_rounded,
                              },
                              size: 17,
                            ),
                            label: Text(token.word),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _speak(latest.target, slow: true),
                            icon: const Icon(Icons.slow_motion_video_rounded),
                            label: const Text('慢速示範'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _speak(latest.target, slow: false),
                            icon: const Icon(Icons.volume_up_outlined),
                            label: const Text('正常語速'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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
