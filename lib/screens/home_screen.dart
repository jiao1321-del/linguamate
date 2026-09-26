import 'package:flutter/material.dart';

import '../widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          Text(
            'LinguaMate',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          const Text('今天也學一點真正用得到的語言 ✨'),
          const SizedBox(height: 24),
          const Row(
            children: [
              StatCard(
                label: '今日新句子',
                value: '5',
                icon: Icons.add_circle_outline,
              ),
              SizedBox(width: 12),
              StatCard(
                label: '待複習',
                value: '12',
                icon: Icons.history,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              StatCard(
                label: '連續學習',
                value: '3 天',
                icon: Icons.local_fire_department_outlined,
              ),
              SizedBox(width: 12),
              StatCard(
                label: '本週時間',
                value: '48m',
                icon: Icons.timer_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日任務',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('1')),
                    title: Text('複習 10 個收藏句子'),
                    subtitle: Text('約 5 分鐘'),
                  ),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('2')),
                    title: Text('完成 1 次 AI 對話'),
                    subtitle: Text('日常聊天情境'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: null,
                    icon: Icon(Icons.play_arrow_rounded),
                    label: Text('開始今日學習'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '最近學習',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          const _SentenceCard(
            source: 'I will reply to you later.',
            translation: '我晚點回覆你。',
            language: 'English',
          ),
          const SizedBox(height: 10),
          const _SentenceCard(
            source: 'Gagamitin ko ito sa studies ko.',
            translation: '我會把它用在學業上。',
            language: 'Tagalog',
          ),
        ],
      ),
    );
  }
}

class _SentenceCard extends StatelessWidget {
  final String source;
  final String translation;
  final String language;

  const _SentenceCard({
    required this.source,
    required this.translation,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        title: Text(
          source,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(translation),
        ),
        trailing: Chip(label: Text(language)),
      ),
    );
  }
}
