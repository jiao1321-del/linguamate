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
    required this.onReviewConversation,
    required this.onClearConversation,
  });

  String get _subtitle {
    switch (targetLanguage) {
      case 'Tagalog':
        return '陪你練自然、日常的 Tagalog';
      case 'Taglish':
        return '陪你練真正會用到的 Taglish';
      default:
        return '陪你把 English 說得更自然';
    }
  }

  Widget _selector({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    required Key key,
  }) {
    return Expanded(
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
          filled: true,
          fillColor: const Color(0xFFF8F5FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            key: key,
            value: value,
            isExpanded: true,
            isDense: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEDE6F7),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const ShiliCoachAvatar(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '汐璃 Shili',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(width: 6),
                        const Text('✨'),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF6F667B),
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                key: const ValueKey('starter-ideas-button'),
                tooltip: '話題靈感',
                visualDensity: VisualDensity.compact,
                onPressed: enabled ? onStarterIdeas : null,
                icon: const Icon(Icons.lightbulb_outline_rounded),
              ),
              const SizedBox(width: 2),
              IconButton(
                key: const ValueKey('conversation-review-button'),
                tooltip: '本次回顧',
                visualDensity: VisualDensity.compact,
                onPressed: enabled ? onReviewConversation : null,
                icon: const Icon(Icons.fact_check_outlined),
              ),
              IconButton(
                key: const ValueKey('clear-chat-button'),
                tooltip: '清除對話',
                visualDensity: VisualDensity.compact,
                onPressed: enabled ? onClearConversation : null,
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _selector(
                key: const ValueKey('language-selector'),
                label: '語言',
                value: targetLanguage,
                items: languages,
                onChanged: onLanguageSelected,
              ),
              const SizedBox(width: 10),
              _selector(
                key: const ValueKey('scenario-selector'),
                label: '情境',
                value: scenario,
                items: scenarios,
                onChanged: onScenarioSelected,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
