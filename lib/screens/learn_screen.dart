import 'package:flutter/material.dart';

class LearnScreen extends StatefulWidget {
  final Future<bool> Function(String text) onSave;
  final VoidCallback onSaved;

  const LearnScreen({
    super.key,
    required this.onSave,
    required this.onSaved,
  });

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _controller = TextEditingController(
    text: 'I will reply to you later.',
  );

  bool _showResult = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentSentence() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入一句想收藏的內容。')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final added = await widget.onSave(text);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added ? '已加入我的學習 ✨' : '這個句子已經收藏過了。',
          ),
        ),
      );

      if (added) {
        widget.onSaved();
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('儲存失敗，請稍後再試。')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
              onPressed: _isSaving ? null : _saveCurrentSentence,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bookmark_add_outlined),
              label: Text(_isSaving ? '儲存中...' : '加入我的學習'),
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
