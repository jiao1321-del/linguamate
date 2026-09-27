import '../models/ai_coach_reply.dart';

class WeaknessClassifier {
  const WeaknessClassifier._();

  static String? classify(AiCoachReply reply) {
    final correction = reply.correction.trim();
    final explanation = reply.explanation.trim();

    if (correction.isEmpty && !_looksLikeCorrection(explanation)) {
      return null;
    }

    final text = '$correction $explanation'.toLowerCase();

    if (_containsAny(text, const [
      '時態',
      '過去式',
      '現在式',
      '未來式',
      'tense',
      'past tense',
      'present tense',
    ])) {
      return '時態';
    }
    if (_containsAny(text, const [
      '冠詞',
      ' article ',
      ' a ',
      ' an ',
      ' the ',
    ])) {
      return '冠詞';
    }
    if (_containsAny(text, const [
      '介系詞',
      '介詞',
      'preposition',
    ])) {
      return '介系詞';
    }
    if (_containsAny(text, const [
      '語序',
      'word order',
      '順序',
    ])) {
      return '語序';
    }
    if (_containsAny(text, const [
      '單數',
      '複數',
      'plural',
      'singular',
    ])) {
      return '單複數';
    }
    if (_containsAny(text, const [
      '拼字',
      '拼寫',
      'spelling',
    ])) {
      return '拼字';
    }
    if (_containsAny(text, const [
      '搭配',
      'collocation',
      '慣用',
      '片語',
    ])) {
      return '單字搭配';
    }
    if (_containsAny(text, const [
      '動詞',
      'verb',
      'to +',
      'gerund',
      '動名詞',
    ])) {
      return '動詞形式';
    }

    return '自然用法';
  }

  static bool _looksLikeCorrection(String text) {
    final normalized = text.toLowerCase();
    return _containsAny(normalized, const [
      '改成',
      '應改',
      '應該用',
      '要用',
      '更自然',
      '比較自然',
      'should use',
      'use ',
    ]);
  }

  static bool _containsAny(String text, List<String> needles) {
    return needles.any(text.contains);
  }
}
