import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/language_analysis.dart';

class LearnScreen extends StatefulWidget {
  final Future<LanguageAnalysis> Function(String text) onAnalyze;
  final Future<bool> Function(
    String text,
    LanguageAnalysis analysis,
  ) onSave;
  final VoidCallback onSaved;

  const LearnScreen({
    super.key,
    required this.onAnalyze,
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

  LanguageAnalysis? _analysis;
  String? _analysisError;
  String? _analyzedText;
  bool _isAnalyzing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;

    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('剪貼簿目前沒有文字。')),
      );
      return;
    }

    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _handleInputChanged(text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已貼上剪貼簿文字。')),
    );
  }

  Future<void> _analyzeCurrentSentence() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      setState(() {
        _analysis = null;
        _analysisError = '請先輸入一句想分析的內容。';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      final result = await widget.onAnalyze(text);
      if (!mounted) return;

      setState(() {
        _analysis = result;
        _analyzedText = text;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _analysis = null;
        _analysisError = error.toString();
        _analyzedText = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _saveCurrentSentence() async {
    final text = _controller.text.trim();
    final analysis = _analysis;

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入一句想收藏的內容。')),
      );
      return;
    }

    if (analysis == null || _analyzedText != text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先完成這句的 AI 分析，再加入我的學習。')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final added = await widget.onSave(text, analysis);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added ? '完整學習卡已加入收藏 ✨' : '這個句子已經收藏過了。',
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

  void _handleInputChanged(String value) {
    final normalized = value.trim();

    if ((_analysis != null || _analysisError != null) &&
        normalized != _analyzedText) {
      setState(() {
        _analysis = null;
        _analysisError = null;
        _analyzedText = null;
      });
    }
  }

  String _languageLabel(String value) {
    switch (value) {
      case 'Chinese':
        return '中文';
      case 'English':
        return 'English';
      case 'Tagalog':
        return 'Tagalog';
      case 'Taglish':
        return 'Taglish';
      case 'Mixed':
        return '混合語言';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;

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
            onChanged: _handleInputChanged,
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
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _isAnalyzing ? null : _pasteText,
              icon: const Icon(Icons.content_paste_rounded),
              label: const Text('貼上文字'),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isAnalyzing ? null : _analyzeCurrentSentence,
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isAnalyzing ? 'AI 分析中...' : '分析並學習'),
          ),
          if (_analysisError != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_analysisError!),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (analysis != null) ...[
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.translate_rounded, size: 18),
                label: Text(
                  '偵測語言：${_languageLabel(analysis.detectedLanguage)}',
                ),
              ),
            ),
            const SizedBox(height: 10),
            _LanguageCard(
              title: '🇹🇼 中文',
              text: analysis.chinese,
            ),
            const SizedBox(height: 10),
            _LanguageCard(
              title: '🇺🇸 English',
              text: analysis.english,
            ),
            const SizedBox(height: 10),
            _LanguageCard(
              title: '🇵🇭 Tagalog / Taglish',
              text: analysis.tagalog,
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💬 語氣與使用情境',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(analysis.tone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✨ 學習重點',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (analysis.learningPoints.isEmpty)
                      const Text('這句目前沒有額外的學習重點。')
                    else
                      for (var i = 0;
                          i < analysis.learningPoints.length;
                          i++) ...[
                        _LearningPointTile(
                          index: i + 1,
                          point: analysis.learningPoints[i],
                        ),
                        if (i != analysis.learningPoints.length - 1)
                          const SizedBox(height: 12),
                      ],
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
            const SizedBox(height: 6),
            Text(
              '會一起保存三語翻譯、語氣與學習重點，之後複習不用重新消耗 AI 額度。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
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
            SelectableText(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningPointTile extends StatelessWidget {
  final int index;
  final LearningPoint point;

  const _LearningPointTile({
    required this.index,
    required this.point,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          child: Text(
            index.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                point.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (point.explanation.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(point.explanation),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
