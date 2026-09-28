import 'package:flutter/material.dart';

import '../models/learner_memory_profile.dart';

class LearnerMemoryScreen extends StatelessWidget {
  final LearnerMemoryProfile profile;

  const LearnerMemoryScreen({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shili 長期記憶 2.0')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Card(
            key: const ValueKey('v138-memory-profile'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shili 目前怎麼理解你的學習狀態',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profile.summary.isEmpty
                        ? '資料還不夠。完成幾次訓練與口說後，這裡會建立長期學習檔案。'
                        : profile.summary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '熟練度會隨長時間未練而逐步衰退，避免「以前會過」被永久視為已掌握。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MemorySection(
            title: '已掌握',
            icon: Icons.verified_outlined,
            items: profile.masteredSkills,
            empty: '還沒有穩定掌握的能力',
          ),
          _MemorySection(
            title: '目前弱點',
            icon: Icons.track_changes_outlined,
            items: profile.weakSkills,
            empty: '目前沒有明顯弱點',
          ),
          _MemorySection(
            title: '久未練習',
            icon: Icons.history_toggle_off_rounded,
            items: profile.staleSkills,
            empty: '近期能力都有維持',
          ),
          _MemorySection(
            title: '常見錯誤',
            icon: Icons.error_outline_rounded,
            items: profile.commonMistakes,
            empty: '目前沒有高頻錯誤',
          ),
          _MemorySection(
            title: '口說常漏字',
            icon: Icons.record_voice_over_outlined,
            items: profile.speakingWeakWords,
            empty: '口說資料還不足',
          ),
        ],
      ),
    );
  }
}

class _MemorySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final String empty;

  const _MemorySection({
    required this.title,
    required this.icon,
    required this.items,
    required this.empty,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(empty)
            else
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final item in items)
                    Chip(label: Text(item)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
