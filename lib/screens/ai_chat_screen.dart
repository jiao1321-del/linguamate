import 'package:flutter/material.dart';

import '../models/ai_coach_reply.dart';
import '../widgets/gilded_card_icon.dart';

typedef AiCoachSender = Future<AiCoachReply> Function(
  String message,
  String targetLanguage,
  List<Map<String, String>> history,
);

typedef ChatLearningSaver = Future<bool> Function(String text);

class AiChatScreen extends StatefulWidget {
  final AiCoachSender onSend;
  final ChatLearningSaver onSaveLearning;

  const AiChatScreen({
    super.key,
    required this.onSend,
    required this.onSaveLearning,
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const _targets = <String>['English', 'Tagalog', 'Taglish'];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String _targetLanguage = 'English';
  bool _isSending = false;
  int? _savingIndex;
  String? _error;
  late List<_ChatEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = [_welcomeEntry(_targetLanguage)];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  _ChatEntry _welcomeEntry(String language) {
    switch (language) {
      case 'Tagalog':
        return const _ChatEntry(
          mine: false,
          text:
              'Kumusta! Mag-practice tayo ng natural na Tagalog. Ano ang ginawa mo ngayon?',
        );
      case 'Taglish':
        return const _ChatEntry(
          mine: false,
          text: 'Hi! Let’s practice natural Taglish. Kumusta ang day mo today?',
        );
      default:
        return const _ChatEntry(
          mine: false,
          text: 'Hi! Let’s practice natural English. What did you do today?',
        );
    }
  }

  void _changeTarget(String language) {
    if (_isSending || _savingIndex != null || language == _targetLanguage) {
      return;
    }

    setState(() {
      _targetLanguage = language;
      _entries = [_welcomeEntry(language)];
      _error = null;
    });
    _controller.clear();
  }

  void _clearConversation() {
    if (_isSending || _savingIndex != null) return;
    setState(() {
      _entries = [_welcomeEntry(_targetLanguage)];
      _error = null;
    });
    _controller.clear();
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _isSending) return;

    final history = _entries
        .map(
          (entry) => {
            'role': entry.mine ? 'user' : 'assistant',
            'content': entry.reply?.reply ?? entry.text,
          },
        )
        .toList(growable: false);

    setState(() {
      _entries.add(_ChatEntry(mine: true, text: message));
      _controller.clear();
      _isSending = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final reply = await widget.onSend(
        message,
        _targetLanguage,
        history,
      );
      if (!mounted) return;

      setState(() {
        _entries.add(
          _ChatEntry(
            mine: false,
            text: reply.reply,
            reply: reply,
          ),
        );
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _saveLearningEntry(int index) async {
    if (_savingIndex != null) return;

    final entry = _entries[index];
    final reply = entry.reply;
    if (reply == null) return;

    final text = reply.hasCorrection ? reply.correction : reply.reply;
    if (text.trim().isEmpty) return;

    setState(() => _savingIndex = index);

    try {
      final added = await widget.onSaveLearning(text);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? '已變成鎏金學習卡並加入收藏 ✨'
                : '這個句子已經收藏過了。',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _savingIndex = null);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'AI 對話教練',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: '清除對話',
                  onPressed:
                      _isSending || _savingIndex != null ? null : _clearConversation,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _targets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final language = _targets[index];
                return ChoiceChip(
                  label: Text(language),
                  selected: _targetLanguage == language,
                  onSelected: (_) => _changeTarget(language),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              itemCount: _entries.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isSending && index == _entries.length) {
                  return const _ThinkingBubble();
                }
                final entry = _entries[index];
                return _ConversationEntry(
                  entry: entry,
                  isSaving: _savingIndex == index,
                  onSave: entry.reply == null
                      ? null
                      : () => _saveLearningEntry(index),
                );
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!)),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: TextField(
              controller: _controller,
              enabled: !_isSending && _savingIndex == null,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: '用 $_targetLanguage 練習...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  tooltip: '送出',
                  onPressed:
                      _isSending || _savingIndex != null ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEntry {
  final bool mine;
  final String text;
  final AiCoachReply? reply;

  const _ChatEntry({
    required this.mine,
    required this.text,
    this.reply,
  });
}

class _ConversationEntry extends StatelessWidget {
  final _ChatEntry entry;
  final bool isSaving;
  final VoidCallback? onSave;

  const _ConversationEntry({
    required this.entry,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final reply = entry.reply;

    return Column(
      crossAxisAlignment:
          entry.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment:
              entry.mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: entry.mine
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SelectableText(entry.text),
          ),
        ),
        if (reply != null)
          Container(
            constraints: const BoxConstraints(maxWidth: 340),
            margin: const EdgeInsets.only(bottom: 14),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reply.hasCorrection) ...[
                      Text(
                        '✨ 更自然的說法',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(reply.correction),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      '💡 學習提示',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(reply.explanation),
                    const SizedBox(height: 12),
                    Text(
                      '🇹🇼 中文意思',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(reply.translation),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        key: const ValueKey('save-chat-learning-card'),
                        onPressed: isSaving ? null : onSave,
                        icon: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const GildedCardIcon(
                                width: 20,
                                height: 26,
                              ),
                        label: Text(
                          isSaving ? '建立學習卡中...' : '加入我的學習',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('AI 思考中...'),
          ],
        ),
      ),
    );
  }
}
