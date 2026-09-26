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

  const ShiliCoachHeader({
    super.key,
    required this.targetLanguage,
    required this.scenario,
    required this.languages,
    required this.scenarios,
    required this.enabled,
    required this.onLanguageSelected,
    required this.onScenarioSelected,
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

  Widget _choiceChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Key? key,
  }) {
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 7),
      onSelected: enabled ? (_) => onTap() : null,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ShiliCoachAvatar(size: 50),
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
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF6F667B),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0EBF6)),
          const SizedBox(height: 10),
          Text(
            '練習語言',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF756B82),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: languages
                .map(
                  (language) => _choiceChip(
                    context: context,
                    label: language,
                    selected: targetLanguage == language,
                    onTap: () => onLanguageSelected(language),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Text(
            '對話情境',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF756B82),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scenarios
                .map(
                  (item) => _choiceChip(
                    context: context,
                    key: ValueKey('scenario-$item'),
                    label: item,
                    selected: scenario == item,
                    onTap: () => onScenarioSelected(item),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
