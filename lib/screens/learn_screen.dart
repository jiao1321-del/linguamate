import 'package:flutter/material.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _controller = TextEditingController(
    text: 'I will reply to you later.',
  );

  bool _showResult = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          Text(
            '學習一個句子',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          const Text('把聊天、工作或生活中真的遇到的句子貼進來。'),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            minLines: 5,
            maxLines: 9,
            decoration: InputDecoration(
              hintText: '輸入 English / 中文 / Tagalog / Taglish...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              setState(() => _showResult = true);
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('分析並學習'),
          ),
          if (_showResult) ...[
            const SizedBox(height: 22),
            const _LanguageCard(
              title: '中文',
              text: '我晚點回覆你。',
            ),
            const SizedBox(height: 10),
            const _LanguageCard(
              title: 'English',
              text: 'I will reply to you later.',
            ),
            const SizedBox(height: 10),
            const _LanguageCard(
              title: 'Tagalog',
              text: 'Babalikan kita mamaya.',
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '學習重點',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '• reply = 回覆\n'
                      '• later = 稍後\n'
                      '• mamaya = 稍後、等一下',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('加入我的學習'),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final String text;

  const _LanguageCard({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
