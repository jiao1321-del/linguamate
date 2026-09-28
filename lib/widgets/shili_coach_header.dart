import 'package:flutter/material.dart';

import 'shili_coach_avatar.dart';

class ShiliCoachHeader extends StatelessWidget {
  final String targetLanguage;
  final String scenario;
  final List<String> languages;
  final List<String> scenarios;
  final bool enabled;
  final ValueChanged<String> onLanguageSelected;
  final ValueChanged<String> onScenarioSelected;
  final VoidCallback onStarterIdeas;
  final VoidCallback onRoleplayMissions;
  final String? activeMissionTitle;
  final VoidCallback onReviewConversation;
  final VoidCallback onClearConversation;

  const ShiliCoachHeader({
    super.key,
    required this.targetLanguage,
    required this.scenario,
    required this.languages,
    required this.scenarios,
    required this.enabled,
    required this.onLanguageSelected,
    required this.onScenarioSelected,
    required this.onStarterIdeas,
    required this.onRoleplayMissions,
    this.activeMissionTitle,
    required this.onReviewConversation,
    required this.onClearConversation,
  });

  String get _subtitle {
    switch (targetLanguage) {
      case 'Tagalog':
        return '陪你練自然 Tagalog';
      case 'Taglish':
        return '陪你練實用 Taglish';
      default:
        return '陪你把 English 說得更自然';
    }
  }

  Widget _selector({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    required Key key,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5FC),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: const Color(0xFF6F667B)),
            const SizedBox(width: 6),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: key,
                  value: value,
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                  ),
                  items: items
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: enabled
                      ? (selected) {
                          if (selected != null) onChanged(selected);
                        }
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMore(String action) {
    switch (action) {
      case 'review':
        onReviewConversation();
        break;
      case 'clear':
        onClearConversation();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEDE6F7),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const ShiliCoachAvatar(size: 40),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '汐璃 Shili',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('✨', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF756B82),
                            height: 1.15,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 38,
                height: 38,
                child: IconButton.filledTonal(
                  key: const ValueKey('starter-ideas-button'),
                  tooltip: '話題靈感',
                  padding: EdgeInsets.zero,
                  onPressed: enabled ? onStarterIdeas : null,
                  icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(width: 3),
              SizedBox(
                width: 38,
                height: 38,
                child: IconButton(
                  key: const ValueKey('roleplay-missions-button'),
                  tooltip: activeMissionTitle == null
                      ? '情境任務'
                      : '任務：$activeMissionTitle',
                  padding: EdgeInsets.zero,
                  onPressed: enabled ? onRoleplayMissions : null,
                  icon: Icon(
                    activeMissionTitle == null
                        ? Icons.theater_comedy_outlined
                        : Icons.theater_comedy_rounded,
                    size: 21,
                  ),
                ),
              ),
              SizedBox(
                width: 38,
                height: 38,
                child: PopupMenuButton<String>(
                  key: const ValueKey('more-ai-actions-button'),
                  tooltip: '更多',
                  padding: EdgeInsets.zero,
                  enabled: enabled,
                  onSelected: _handleMore,
                  icon: const Icon(Icons.more_horiz_rounded, size: 22),
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      key: ValueKey('conversation-review-button'),
                      value: 'review',
                      child: Row(
                        children: [
                          Icon(Icons.school_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('單字・文法・回顧'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      key: ValueKey('clear-chat-button'),
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('清除對話'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _selector(
                key: const ValueKey('language-selector'),
                value: targetLanguage,
                items: languages,
                onChanged: onLanguageSelected,
                icon: Icons.translate_rounded,
              ),
              const SizedBox(width: 8),
              _selector(
                key: const ValueKey('scenario-selector'),
                value: scenario,
                items: scenarios,
                onChanged: onScenarioSelected,
                icon: Icons.work_outline_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
