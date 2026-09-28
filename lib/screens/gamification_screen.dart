import 'package:flutter/material.dart';

import '../models/gamification.dart';

class GamificationScreen extends StatelessWidget {
  final GamificationSnapshot snapshot;

  const GamificationScreen({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('成長系統 2.0')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Card(
            key: const ValueKey('v144-gamification'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: snapshot.levelProgress),
                    duration: const Duration(milliseconds: 650),
                    builder: (context, value, child) => Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 112,
                          height: 112,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 10,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              'Lv.${snapshot.level}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(snapshot.title),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${snapshot.xp} XP · 連續 ${snapshot.streak} 天',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '距離下一級還差 ${snapshot.xpPerLevel - snapshot.xpIntoLevel} XP',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _QuestSection(
            title: '每日任務',
            quests: snapshot.dailyQuests,
          ),
          const SizedBox(height: 14),
          _QuestSection(
            title: '每週任務',
            quests: snapshot.weeklyQuests,
          ),
        ],
      ),
    );
  }
}

class _QuestSection extends StatelessWidget {
  final String title;
  final List<LearningQuest> quests;

  const _QuestSection({
    required this.title,
    required this.quests,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 10),
            for (final quest in quests) ...[
              Row(
                children: [
                  Icon(
                    quest.completed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quest.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(quest.reward),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: quest.ratio,
                minHeight: 7,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 4),
              Text(
                '${quest.progress.clamp(0, quest.target)} / ${quest.target}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
