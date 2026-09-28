import 'package:flutter/material.dart';

import '../models/roleplay_campaign.dart';

class RoleplayCampaignScreen extends StatelessWidget {
  final RoleplayCampaign campaign;
  final Set<String> completedMissionIds;
  final ValueChanged<String> onStartMission;

  const RoleplayCampaignScreen({
    super.key,
    required this.campaign,
    required this.completedMissionIds,
    required this.onStartMission,
  });

  bool _unlocked(int index) {
    if (index == 0) return true;
    return completedMissionIds.contains(
      campaign.chapters[index - 1].missionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('情境世界 3.0')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Card(
            key: const ValueKey('v141-language-rpg'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(campaign.description),
                  const SizedBox(height: 10),
                  Text(
                    '已完成 ${completedMissionIds.length.clamp(0, campaign.chapters.length)} / ${campaign.chapters.length} 關',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < campaign.chapters.length; index++)
            _CampaignChapterCard(
              chapter: campaign.chapters[index],
              index: index,
              unlocked: _unlocked(index),
              completed: completedMissionIds.contains(
                campaign.chapters[index].missionId,
              ),
              onStart: () =>
                  onStartMission(campaign.chapters[index].missionId),
            ),
        ],
      ),
    );
  }
}

class _CampaignChapterCard extends StatelessWidget {
  final RoleplayCampaignChapter chapter;
  final int index;
  final bool unlocked;
  final bool completed;
  final VoidCallback onStart;

  const _CampaignChapterCard({
    required this.chapter,
    required this.index,
    required this.unlocked,
    required this.completed,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('rpg-chapter-${chapter.id}'),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          child: Icon(
            completed
                ? Icons.check_rounded
                : unlocked
                    ? Icons.play_arrow_rounded
                    : Icons.lock_outline_rounded,
          ),
        ),
        title: Text(
          chapter.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(chapter.subtitle),
        trailing: FilledButton.tonal(
          onPressed: unlocked ? onStart : null,
          child: Text(completed ? '再挑戰' : '開始'),
        ),
      ),
    );
  }
}
