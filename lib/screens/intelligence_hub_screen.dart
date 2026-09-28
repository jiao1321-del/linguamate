import 'package:flutter/material.dart';

import '../models/intelligence_core.dart';

class IntelligenceHubScreen extends StatelessWidget {
  final IntelligenceCoreSnapshot snapshot;
  final ValueChanged<String> onAction;
  final VoidCallback onOpenCloud;
  final VoidCallback onOpenMemory;
  final VoidCallback onOpenSpeaking;
  final VoidCallback onOpenLiveVoice;
  final VoidCallback onOpenCampaign;
  final VoidCallback onOpenRoadmap;
  final VoidCallback onOpenGamification;
  final VoidCallback onOpenInsights;

  const IntelligenceHubScreen({
    super.key,
    required this.snapshot,
    required this.onAction,
    required this.onOpenCloud,
    required this.onOpenMemory,
    required this.onOpenSpeaking,
    required this.onOpenLiveVoice,
    required this.onOpenCampaign,
    required this.onOpenRoadmap,
    required this.onOpenGamification,
    required this.onOpenInsights,
  });

  @override
  Widget build(BuildContext context) {
    final next = snapshot.nextBestAction;
    return Scaffold(
      appBar: AppBar(title: const Text('LinguaMate Intelligence Core')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Card(
            key: const ValueKey('v146-intelligence-core'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'V1.46 · Next Best Action',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    next.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(next.reason),
                  const SizedBox(height: 10),
                  Text(
                    '預估 ${next.estimatedMinutes} 分鐘 · 個人難度 Lv.${snapshot.adaptiveDifficulty}/10',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey('start-next-best-action'),
                      onPressed: () => onAction(next.action),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('開始 Shili 建議的下一步'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _StatusGrid(snapshot: snapshot),
          const SizedBox(height: 14),
          const Text(
            'Intelligence Modules',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          _ModuleTile(
            version: 'V1.37',
            title: 'Cloud Sync 2.0',
            subtitle: '自動合併同步、離線保護與衝突處理',
            icon: Icons.cloud_sync_outlined,
            onTap: onOpenCloud,
          ),
          _ModuleTile(
            version: 'V1.38',
            title: 'Shili 長期記憶 2.0',
            subtitle: '掌握、弱點、遺忘與口說問題形成長期檔案',
            icon: Icons.psychology_alt_outlined,
            onTap: onOpenMemory,
          ),
          _ModuleTile(
            version: 'V1.39',
            title: '口說教練 3.0',
            subtitle: '逐字診斷、Shadowing 與常漏字',
            icon: Icons.record_voice_over_outlined,
            onTap: onOpenSpeaking,
          ),
          _ModuleTile(
            version: 'V1.40',
            title: 'Shili Live Voice',
            subtitle: '連續聽說輪替、慢速與中文提示',
            icon: Icons.graphic_eq_rounded,
            onTap: onOpenLiveVoice,
          ),
          _ModuleTile(
            version: 'V1.41',
            title: '情境世界 3.0',
            subtitle: '海外工作篇連續劇情與關卡解鎖',
            icon: Icons.sports_esports_outlined,
            onTap: onOpenCampaign,
          ),
          _ModuleTile(
            version: 'V1.43',
            title: '30 天 AI 課程',
            subtitle: '長期目標、週 Checkpoint 與每日路線',
            icon: Icons.calendar_month_outlined,
            onTap: onOpenRoadmap,
          ),
          _ModuleTile(
            version: 'V1.44',
            title: '成長系統 2.0',
            subtitle: 'XP、稱號、每日與每週任務',
            icon: Icons.emoji_events_outlined,
            onTap: onOpenGamification,
          ),
          _ModuleTile(
            version: 'V1.45',
            title: 'Learning Intelligence',
            subtitle: '7/30 天趨勢、本週報告與下一週重點',
            icon: Icons.insights_outlined,
            onTap: onOpenInsights,
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  final IntelligenceCoreSnapshot snapshot;

  const _StatusGrid({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final data = <(String, String)>[
      ('Lv.', '${snapshot.gamification.level}'),
      ('待複習', '${snapshot.dueReviewCount}'),
      ('錯題', '${snapshot.activeMistakeCount}'),
      ('30 天', '${snapshot.roadmapProgress}'),
      ('RPG', '${snapshot.campaignProgress}'),
      ('課程', '${snapshot.courseProgress}'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.45,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final item in data)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2EDF9),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.$2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                Text(
                  item.$1,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final String version;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.version,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(
          '$version · $title',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
