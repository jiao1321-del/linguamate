import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ai_chat_state.dart';
import '../models/ai_coach_reply.dart';
import '../services/ai_chat_store.dart';
import '../widgets/gilded_card_icon.dart';
import '../widgets/shili_coach_avatar.dart';
import '../widgets/shili_coach_header.dart';

typedef AiCoachSender = Future<AiCoachReply> Function(
  String message,
  String targetLanguage,
  List<Map<String, String>> history,
);

typedef ChatLearningSaver = Future<bool> Function(String text);

class AiChatScreen extends StatefulWidget {
  final AiCoachSender onSend;
  final ChatLearningSaver onSaveLearning;
  final AiChatStore chatStore;

  const AiChatScreen({
    super.key,
    required this.onSend,
    required this.onSaveLearning,
    this.chatStore = const AiChatStore(),
  });

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const _targets = <String>['English', 'Tagalog', 'Taglish'];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String _targetLanguage = 'English';
  bool _isRestoring = true;
  bool _isSending = false;
  int? _savingIndex;
  String? _error;
  late List<AiChatMessage> _entries;

  @override
  void initState() {
    super.initState();
    _entries = [_welcomeEntry(_targetLanguage)];
    _restoreConversation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  AiChatMessage _welcomeEntry(String language) {
    switch (language) {
      case 'Tagalog':
        return const AiChatMessage(
          mine: false,
          text:
              'Hi, ako si Shili ✨ Mag-practice tayo ng natural na Tagalog. Ano ang gusto mong pag-usapan today?',
        );
      case 'Taglish':
        return const AiChatMessage(
          mine: false,
          text:
              'Hi, I’m Shili ✨ Let’s practice natural Taglish together. Kumusta ang day mo today?',
        );
      default:
        return const AiChatMessage(
          mine: false,
          text:
              'Hi, I’m Shili ✨ Let’s make your English sound more natural. What do you feel like talking about today?',
        );
    }
  }

  Future<void> _restoreConversation() async {
    final saved = await widget.chatStore.load();
    if (!mounted) return;

    final language = saved != null && _targets.contains(saved.targetLanguage)
        ? saved.targetLanguage
        : 'English';
    final messages = saved?.messages ?? const <AiChatMessage>[];

    setState(() {
      _targetLanguage = language;
      _entries = messages.isEmpty ? [_welcomeEntry(language)] : messages;
      _isRestoring = false;
    });

    if (messages.isNotEmpty) {
      _scrollToBottom();
    }
  }

  Future<void> _persistConversation() {
    return widget.chatStore.save(
      AiChatState(
        targetLanguage: _targetLanguage,
        messages: _entries,
      ),
    );
  }

  Future<void> _persistConversationSafely() async {
    try {
      await _persistConversation();
    } catch (_) {
      // Local persistence must never block sending a chat message.
    }
  }

  Future<void> _changeTarget(String language) async {
    if (_isRestoring ||
        _isSending ||
        _savingIndex != null ||
        language == _targetLanguage) {
      return;
    }

    setState(() {
      _targetLanguage = language;
      _entries = [_welcomeEntry(language)];
      _error = null;
    });
    _controller.clear();
    await _persistConversation();
  }

  Future<void> _clearConversation() async {
    if (_isRestoring || _isSending || _savingIndex != null) return;

    setState(() {
      _entries = [_welcomeEntry(_targetLanguage)];
      _error = null;
    });
    _controller.clear();
    await _persistConversation();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI 對話紀錄已清除。')),
    );
  }

  Future<void> _sendMessage() async {
    if (_isRestoring || _isSending || _savingIndex != null) return;

    // Capture the current controller value BEFORE changing focus. This keeps
    // the user's in-progress iOS IME composition from being lost.
    final message = _controller.value.text.trim();
    if (message.isEmpty) return;

    final history = _entries
        .map(
          (entry) => {
            'role': entry.mine ? 'user' : 'assistant',
            'content': entry.reply?.reply ?? entry.text,
          },
        )
        .toList(growable: false);

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _entries.add(AiChatMessage(mine: true, text: message));
      _controller.clear();
      _isSending = true;
      _error = null;
    });
    _scrollToBottom();

    // Persistence is best-effort and runs independently from the network
    // request so local storage can never delay or block sending.
    unawaited(_persistConversationSafely());

    try {
      final reply = await widget.onSend(
        message,
        _targetLanguage,
        history,
      );
      if (!mounted) return;

      setState(() {
        _entries.add(
          AiChatMessage(
            mine: false,
            text: reply.reply,
            reply: reply,
          ),
        );
      });
      unawaited(_persistConversationSafely());
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
                if (_isRestoring)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    tooltip: '清除對話',
                    onPressed: _isSending || _savingIndex != null
                        ? null
                        : _clearConversation,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
              ],
            ),
          ),
          ShiliCoachHeader(targetLanguage: _targetLanguage),
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
                  onSelected: _isRestoring
                      ? null
                      : (_) => _changeTarget(language),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled:
                        !_isRestoring && !_isSending && _savingIndex == null,
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: _isRestoring
                          ? '正在載入對話...'
                          : '用 $_targetLanguage 練習...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Listener(
                  key: const ValueKey('send-chat-message'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) {
                    if (_isRestoring ||
                        _isSending ||
                        _savingIndex != null) {
                      return;
                    }
                    unawaited(_sendMessage());
                  },
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      onPressed:
                          _isRestoring || _isSending || _savingIndex != null
                              ? null
                              : _sendMessage,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationEntry extends StatelessWidget {
  final AiChatMessage entry;
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
        if (entry.mine)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SelectableText(entry.text),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShiliCoachAvatar(size: 34),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 278),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SelectableText(entry.text),
                  ),
                ),
              ],
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const ShiliCoachAvatar(size: 34),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
                  Text('Shili 正在想怎麼回你...'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
