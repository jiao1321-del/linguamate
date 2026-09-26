import 'ai_coach_reply.dart';

class AiChatMessage {
  final bool mine;
  final String text;
  final AiCoachReply? reply;

  const AiChatMessage({
    required this.mine,
    required this.text,
    this.reply,
  });

  Map<String, dynamic> toJson() {
    return {
      'mine': mine,
      'text': text,
      'reply': reply?.toJson(),
    };
  }

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    final rawReply = json['reply'];
    return AiChatMessage(
      mine: json['mine'] == true,
      text: (json['text'] as String? ?? '').trim(),
      reply: rawReply is Map
          ? AiCoachReply.fromJson(Map<String, dynamic>.from(rawReply))
          : null,
    );
  }
}

class AiChatState {
  final String targetLanguage;
  final String scenario;
  final List<AiChatMessage> messages;

  const AiChatState({
    required this.targetLanguage,
    this.scenario = '自由對話',
    required this.messages,
  });

  Map<String, dynamic> toJson() {
    return {
      'targetLanguage': targetLanguage,
      'scenario': scenario,
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }

  factory AiChatState.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages
            .whereType<Map>()
            .map(
              (message) => AiChatMessage.fromJson(
                Map<String, dynamic>.from(message),
              ),
            )
            .where((message) => message.text.isNotEmpty)
            .toList(growable: false)
        : const <AiChatMessage>[];

    return AiChatState(
      targetLanguage: (json['targetLanguage'] as String? ?? 'English').trim(),
      scenario: (json['scenario'] as String? ?? '自由對話').trim(),
      messages: messages,
    );
  }
}
