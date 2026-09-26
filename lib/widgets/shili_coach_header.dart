import 'package:flutter/material.dart';

import 'shili_coach_avatar.dart';

class ShiliCoachHeader extends StatelessWidget {
  final String targetLanguage;

  const ShiliCoachHeader({
    super.key,
    required this.targetLanguage,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF2ECFA),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              targetLanguage,
              style: const TextStyle(
                color: Color(0xFF6F4E95),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
