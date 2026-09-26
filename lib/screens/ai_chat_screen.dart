import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ai_chat_state.dart';
import '../models/ai_coach_reply.dart';
import '../services/ai_chat_store.dart';
import '../services/practice_starter_service.dart';
import '../widgets/gilded_card_icon.dart';
import '../widgets/shili_coach_avatar.dart';
import '../widgets/shili_coach_header.dart';

typedef AiCoachSender = Future<AiCoachReply> Function(
  String message,
  String targetLanguage,
  String scenario,
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
  static const _scenarios = <String>[
    '自由對話',
    '日常生活',
    '工作職場',
    '旅行',
  ];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String _targetLanguage = 'English';
  String _scenario = '自由對話';
  bool _isRestoring = true;
  bool _isSending = false;
  int? _savingIndex;
  String? _error;
  late List<AiChatMessage> _entries;

  @override
  void initState() {
    super.initState();
    _entries = [_welcomeEntry(_targetLanguage, _scenario)];
    _restoreConversation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  AiChatMessage _welcomeEntry(String language, String scenario) {
    final topic = switch (scenario) {
      '日常生活' => 'daily life',
      '工作職場' => 'workplace situations',
      '旅行' => 'travel',
      _ => 'anything you like',
    };

    switch (language) {
      case 'Tagalog':
        return AiChatMessage(
          mine: false,
          text:
              'Hi, ako si Shili ✨ Mag-practice tayo ng natural na Tagalog tungkol sa $topic. Simulan mo kapag ready ka.',
        );
      case 'Taglish':
        return AiChatMessage(
          mine: false,
          text:
              'Hi, I’m Shili ✨ Let’s practice natural Taglish around $topic. Start ka lang when you’re ready.',
        );
      default:
        return AiChatMessage(
          mine: false,
          text:
              'Hi, I’m Shili ✨ Let’s practice natural English around $topic. Start whenever you’re ready.',
        );
    }
  }

  Future<void> _restoreConversation() async {
    final saved = await widget.chatStore.load();
    if (!mounted) return;

    final language = saved != null && _targets.contains(saved.targetLanguage)
        ? saved.targetLanguage
        : 'English';
    final scenario = saved != null && _scenarios.contains(saved.scenario)
        ? saved.scenario
        : '自由對話';
    final messages = saved?.messages ?? const <AiChatMessage>[];

    setState(() {
      _targetLanguage = language;
      _scenario = scenario;
      _entries =
          messages.isEmpty ? [_welcomeEntry(language, scenario)] : messages;
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
        scenario: _scenario,
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

  void _clearComposerAfterSend(String sentMessage) {
    _controller.value = TextEditingValue.empty;

    unawaited(
      Future<void>(() async {
        for (final delay in const [
          Duration(milliseconds: 80),
          Duration(milliseconds: 220),
        ]) {
          await Future<void>.delayed(delay);
          if (!mounted) return;

          if (_controller.text.trim() == sentMessage) {
            _controller.value = TextEditingValue.empty;
          }
        }
      }),
    );
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
      _entries = [_welcomeEntry(language, _scenario)];
      _error = null;
    });
    _controller.clear();
    await _persistConversation();
  }

  Future<void> _changeScenario(String scenario) async {
    if (_isRestoring ||
        _isSending ||
        _savingIndex != null ||
        scenario == _scenario) {
      return;
    }

    setState(() {
      _scenario = scenario;
      _entries = [_welcomeEntry(_targetLanguage, scenario)];
      _error = null;
    });
    _controller.clear();
    await _persistConversation();
  }

  Future<void> _showStarterIdeas() async {
    if (_isRestoring || _isSending || _savingIndex != null) return;

    final latestSuggestions = _entries.reversed
        .map((entry) => entry.reply?.suggestions ?? const <AiCoachSuggestion>[])
        .firstWhere(
          (items) => items.isNotEmpty,
          orElse: () => const <AiCoachSuggestion>[],
        );

    final isDynamic = latestSuggestions.isNotEmpty;
    final ideas = isDynamic
        ? latestSuggestions
            .map(
              (item) => PracticeStarter(
                text: item.text,
                chinese: item.chinese,
              ),
            )
            .toList(growable: false)
        : PracticeStarterService.ideas(
            language: _targetLanguage,
            scenario: _scenario,
          );

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                Text(
                  '話題靈感 · $_scenario',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDynamic
                      ? '依照目前對話推薦，下一輪會隨聊天內容更新。'
                      : '先從情境題目開始；對話後會自動變成動態推薦。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF756B82),
                      ),
                ),
                const SizedBox(height: 12),
                for (final idea in ideas)
                  ListTile(
                    key: ValueKey('starter-idea-${idea.text}'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.chat_bubble_outline_rounded),
                    title: Text(idea.text),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        idea.chinese,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF756B82),
                            ),
                      ),
                    ),
                    trailing: const Icon(Icons.north_west_rounded, size: 18),
                    onTap: () => Navigator.of(context).pop(idea.text),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    _controller.value = TextEditingValue(
      text: selected,
      selection: TextSelection.collapsed(offset: selected.length),
    );
  }

  List<_ConversationReviewItem> _conversationReviewItems() {
    final items = <_ConversationReviewItem>[];
    String? latestUserText;

    for (var index = 0; index < _entries.length; index++) {
      final entry = _entries[index];
      if (entry.mine) {
        latestUserText = entry.text;
        continue;
      }

      final reply = entry.reply;
      if (reply == null) continue;

      final hasLearningPoint =
          reply.hasCorrection || reply.explanation.trim().isNotEmpty;
      if (!hasLearningPoint) continue;

      items.add(
        _ConversationReviewItem(
          entryIndex: index,
          userText: latestUserText ?? '',
          reply: reply,
        ),
      );
    }

    if (items.length <= 8) return items;
    return items.sublist(items.length - 8);
  }

  Future<void> _showConversationReview() async {
    if (_isRestoring || _isSending || _savingIndex != null) return;

    final items = _conversationReviewItems();
    final userTurns = _entries.where((entry) => entry.mine).length;
    final correctionCount =
        items.where((item) => item.reply.hasCorrection).length;

    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text(
                  '本次對話回顧',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$userTurns 個對話回合 · $correctionCount 個修正重點',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF756B82),
                      ),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F5FC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '目前還沒有需要整理的學習重點。再和 Shili 多聊幾句後回來看看 ✨',
                    ),
                  )
                else
                  for (var position = 0;
                      position < items.length;
                      position++) ...[
                    _ConversationReviewCard(
                      item: items[position],
                      onSave: () => Navigator.of(context).pop(
                        items[position].entryIndex,
                      ),
                    ),
                    if (position != items.length - 1)
                      const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedIndex == null) return;
    await _saveLearningEntry(selectedIndex);
  }

  Future<void> _clearConversation() async {
    if (_isRestoring || _isSending || _savingIndex != null) return;

    setState(() {
      _entries = [_welcomeEntry(_targetLanguage, _scenario)];
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

    setState(() {
      _entries.add(AiChatMessage(mine: true, text: message));
      _isSending = true;
      _error = null;
    });

    _clearComposerAfterSend(message);
    _scrollToBottom();

    // Persistence is best-effort and runs independently from the network
    // request so local storage can never delay or block sending.
    unawaited(_persistConversationSafely());

    try {
      final reply = await widget.onSend(
        message,
        _targetLanguage,
        _scenario,
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
    void jumpOnNextFrame(int remainingFrames) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;

        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );

        if (remainingFrames > 1) {
          jumpOnNextFrame(remainingFrames - 1);
        }
      });
    }

    jumpOnNextFrame(3);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 10),
          ShiliCoachHeader(
            targetLanguage: _targetLanguage,
            scenario: _scenario,
            languages: _targets,
            scenarios: _scenarios,
            enabled:
                !_isRestoring && !_isSending && _savingIndex == null,
            onLanguageSelected: _changeTarget,
            onScenarioSelected: _changeScenario,
            onStarterIdeas: _showStarterIdeas,
            onReviewConversation: _showConversationReview,
            onClearConversation: _clearConversation,
          ),
          const SizedBox(height: 4),
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
                    key: const ValueKey('chat-input'),
                    controller: _controller,
                    enabled: !_isRestoring && _savingIndex == null,
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!_isSending) {
                        unawaited(_sendMessage());
                      }
                    },
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
                SizedBox(
                  width: 50,
                  height: 50,
                  child: IconButton.filled(
                    key: const ValueKey('send-chat-message'),
                    tooltip: '送出',
                    onPressed:
                        _isRestoring || _isSending || _savingIndex != null
                            ? null
                            : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
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

class _ConversationReviewItem {
  final int entryIndex;
  final String userText;
  final AiCoachReply reply;

  const _ConversationReviewItem({
    required this.entryIndex,
    required this.userText,
    required this.reply,
  });
}

class _ConversationReviewCard extends StatelessWidget {
  final _ConversationReviewItem item;
  final VoidCallback onSave;

  const _ConversationReviewCard({
    required this.item,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final reply = item.reply;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.userText.trim().isNotEmpty) ...[
              Text(
                '你說',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF756B82),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(item.userText),
              const SizedBox(height: 10),
            ],
            if (reply.hasCorrection) ...[
              Text(
                '✨ 更自然',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(reply.correction),
              const SizedBox(height: 10),
            ],
            if (reply.explanation.trim().isNotEmpty) ...[
              Text(
                '💡 學習重點',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(reply.explanation),
              const SizedBox(height: 10),
            ],
            if (reply.translation.trim().isNotEmpty) ...[
              Text(
                '🇹🇼 Shili 中文',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              Text(reply.translation),
              const SizedBox(height: 12),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                key: ValueKey('review-save-${item.entryIndex}'),
                onPressed: onSave,
                icon: const GildedCardIcon(width: 18, height: 24),
                label: const Text('加入我的學習'),
              ),
            ),
          ],
        ),
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
