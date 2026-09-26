import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_chat_state.dart';

class AiChatStore {
  static const storageKey = 'ai_chat_state_v1';
  static const maxMessages = 60;

  const AiChatStore();

  Future<AiChatState?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AiChatState.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(AiChatState state) async {
    final preferences = await SharedPreferences.getInstance();
    final messages = state.messages.length <= maxMessages
        ? state.messages
        : state.messages.sublist(state.messages.length - maxMessages);

    final normalized = AiChatState(
      targetLanguage: state.targetLanguage,
      messages: messages,
    );

    await preferences.setString(
      storageKey,
      jsonEncode(normalized.toJson()),
    );
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(storageKey);
  }
}
