import 'dart:async';

import 'package:flutter/material.dart';

import '../models/ai_coach_reply.dart';
import '../services/speech_coach_service.dart';

typedef LiveVoiceSender = Future<AiCoachReply> Function(
  String message,
  String targetLanguage,
  String scenario,
  List<Map<String, String>> history,
);

class LiveVoiceScreen extends StatefulWidget {
  final LiveVoiceSender onSend;
  final String learnerMemory;
  final SpeechCoachService? speechService;

  const LiveVoiceScreen({
    super.key,
    required this.onSend,
    this.learnerMemory = '',
    this.speechService,
  });

  @override
  State<LiveVoiceScreen> createState() => _LiveVoiceScreenState();
}

class _LiveVoiceScreenState extends State<LiveVoiceScreen> {
  late final SpeechCoachService _speech;
  final List<_VoiceTurn> _turns = <_VoiceTurn>[];

  bool _active = false;
  bool _busy = false;
  bool _slow = false;
  bool _showChineseHint = true;
  String _language = 'English';
  String _status = '準備開始';
  String? _error;

  @override
  void initState() {
    super.initState();
    _speech = widget.speechService ?? createSpeechCoachService();
  }

  @override
  void dispose() {
    _active = false;
    _speech.stop();
    super.dispose();
  }

  String get _languageTag => switch (_language) {
        'Tagalog' => 'fil-PH',
        'Taglish' => 'en-PH',
        _ => 'en-US',
      };

  Future<void> _toggleSession() async {
    if (_active) {
      setState(() {
        _active = false;
        _status = '已停止';
      });
      _speech.stop();
      return;
    }

    if (!_speech.canListen || !_speech.canSpeak) {
      setState(() => _error = '目前裝置無法同時使用語音辨識與朗讀。');
      return;
    }

    setState(() {
      _active = true;
      _error = null;
      _status = '正在啟動語音對話…';
    });
    unawaited(_runLoop());
  }

  Future<void> _runLoop() async {
    while (mounted && _active) {
      setState(() {
        _busy = true;
        _status = '輪到你說話 🎙️';
      });

      final transcript = await _speech.listen(languageTag: _languageTag);
      if (!mounted || !_active) break;

      final normalized = transcript?.trim() ?? '';
      if (normalized.isEmpty) {
        setState(() {
          _active = false;
          _busy = false;
          _status = '沒有聽清楚，點開始再試一次';
        });
        break;
      }

      setState(() {
        _turns.add(_VoiceTurn(mine: true, text: normalized));
        _status = 'Shili 正在回覆…';
      });

      try {
        final history = _turns
            .takeLast(10)
            .map(
              (turn) => <String, String>{
                'role': turn.mine ? 'user' : 'assistant',
                'content': turn.text,
              },
            )
            .toList(growable: false);

        final memory = widget.learnerMemory.trim();
        final scenario = memory.isEmpty
            ? '自由對話'
            : '自由對話\n\nLearner memory: $memory';
        final reply = await widget.onSend(
          normalized,
          _language,
          scenario,
          history,
        );

        if (!mounted || !_active) break;
        setState(() {
          _turns.add(
            _VoiceTurn(
              mine: false,
              text: reply.reply,
              translation: reply.translation,
            ),
          );
          _status = _slow ? 'Shili 慢速示範中…' : 'Shili 回覆中…';
        });

        await _speech.speak(
          text: reply.reply,
          languageTag: _languageTag,
          rate: _slow ? 0.34 : 0.47,
        );
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _active = false;
          _error = error.toString();
          _status = '語音對話暫停';
        });
        break;
      }
    }

    if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shili Live Voice')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Card(
                key: const ValueKey('v140-live-voice-card'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.graphic_eq_rounded),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'V1.40 · 連續語音對話',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Chip(label: Text(_status)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _language,
                              decoration:
                                  const InputDecoration(labelText: '語言'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'English',
                                  child: Text('English'),
                                ),
                                DropdownMenuItem(
                                  value: 'Tagalog',
                                  child: Text('Tagalog'),
                                ),
                                DropdownMenuItem(
                                  value: 'Taglish',
                                  child: Text('Taglish'),
                                ),
                              ],
                              onChanged: _active
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _language = value);
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text('慢速'),
                            selected: _slow,
                            onSelected: _active
                                ? null
                                : (value) => setState(() => _slow = value),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('顯示中文提示'),
                        value: _showChineseHint,
                        onChanged: (value) =>
                            setState(() => _showChineseHint = value),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const ValueKey('live-voice-toggle'),
                          onPressed: _busy && !_active ? null : _toggleSession,
                          icon: Icon(
                            _active
                                ? Icons.stop_circle_outlined
                                : Icons.phone_in_talk_outlined,
                          ),
                          label: Text(_active ? '停止語音對話' : '開始語音對話'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '開始後會自動輪流「聽你說 → Shili 回覆 → 再聽你說」。受瀏覽器麥克風權限限制時，可停止後重新開始。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MaterialBanner(
                  content: Text(_error!),
                  actions: [
                    TextButton(
                      onPressed: () => setState(() => _error = null),
                      child: const Text('關閉'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _turns.length,
                itemBuilder: (context, index) {
                  final turn = _turns[index];
                  return Align(
                    alignment: turn.mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: turn.mine
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(turn.text),
                          if (!turn.mine &&
                              _showChineseHint &&
                              turn.translation.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              turn.translation,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceTurn {
  final bool mine;
  final String text;
  final String translation;

  const _VoiceTurn({
    required this.mine,
    required this.text,
    this.translation = '',
  });
}

extension _TakeLastVoice<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}
