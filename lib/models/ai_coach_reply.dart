class AiCoachReply {
  final String reply;
  final String correction;
  final String explanation;
  final String translation;

  const AiCoachReply({
    required this.reply,
    required this.correction,
    required this.explanation,
    required this.translation,
  });

  bool get hasCorrection => correction.trim().isNotEmpty;

  factory AiCoachReply.fromJson(Map<String, dynamic> json) {
    return AiCoachReply(
      reply: (json['reply'] as String? ?? '').trim(),
      correction: (json['correction'] as String? ?? '').trim(),
      explanation: (json['explanation'] as String? ?? '').trim(),
      translation: (json['translation'] as String? ?? '').trim(),
    );
  }
}
