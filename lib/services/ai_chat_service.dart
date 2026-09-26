import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_coach_reply.dart';

class AiChatException implements Exception {
  final String message;

  const AiChatException(this.message);

  @override
  String toString() => message;
}

class AiChatService {
  static const _endpoint =
      'https://svzsynadhzvflauxppwn.supabase.co/functions/v1/chat-language';

  static const _publishableKey =
      'sb_publishable_UoxuXbXG8Qvy0Snte4jmPQ_IIPI-IzR';
  static const _legacyAnonJwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN2enN5bmFkaHp2ZmxhdXhwcHduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0NDIxNjIsImV4cCI6MjEwNjAxODE2Mn0.zhl-nd806Gs_VGmNg70UEKEWwck-Iielnb6JCD8sRjI';

  Future<AiCoachReply> send(
    String message,
    String targetLanguage,
    List<Map<String, String>> history,
  ) async {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      throw const AiChatException('請先輸入想和 AI 練習的內容。');
    }

    if (normalized.length > 1000) {
      throw const AiChatException('訊息太長，請控制在 1000 個字元以內。');
    }

    late final http.Response response;

    try {
      response = await http
          .post(
            Uri.parse(_endpoint),
            headers: const {
              'Content-Type': 'application/json',
              'apikey': _publishableKey,
              'Authorization': 'Bearer $_legacyAnonJwt',
            },
            body: jsonEncode({
              'message': normalized,
              'targetLanguage': targetLanguage,
              'history': history.takeLast(8).toList(),
            }),
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const AiChatException('AI 回覆逾時，請稍後再試。');
    } catch (_) {
      throw const AiChatException('目前無法連線到 AI 對話服務，請稍後再試。');
    }

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(response.body);
      payload = decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
    } catch (_) {
      throw const AiChatException('AI 服務回傳了無法讀取的內容。');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = payload['error'] as String?;
      final message = payload['message'] as String?;

      if (code == 'AI_BACKEND_NOT_CONFIGURED') {
        throw const AiChatException(
          'AI 後端尚未設定完成，請先設定 OpenAI API Key。',
        );
      }

      throw AiChatException(
        message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'AI 對話失敗，請稍後再試。',
      );
    }

    final rawReply = payload['reply'];
    if (rawReply is! Map) {
      throw const AiChatException('AI 回覆格式不正確。');
    }

    final reply = AiCoachReply.fromJson(
      Map<String, dynamic>.from(rawReply),
    );

    if (reply.reply.isEmpty || reply.translation.isEmpty) {
      throw const AiChatException('AI 回覆內容不完整，請再試一次。');
    }

    return reply;
  }
}

extension _TakeLastExtension<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}
