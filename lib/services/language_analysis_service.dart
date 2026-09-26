import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/language_analysis.dart';

class LanguageAnalysisException implements Exception {
  final String message;

  const LanguageAnalysisException(this.message);

  @override
  String toString() => message;
}

class LanguageAnalysisService {
  static const _endpoint =
      'https://svzsynadhzvflauxppwn.supabase.co/functions/v1/analyze-language';

  // Supabase browser keys are public client credentials. The OpenAI secret stays
  // only inside the Edge Function environment and is never shipped with the app.
  static const _publishableKey =
      'sb_publishable_UoxuXbXG8Qvy0Snte4jmPQ_IIPI-IzR';
  static const _legacyAnonJwt =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN2enN5bmFkaHp2ZmxhdXhwcHduIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0NDIxNjIsImV4cCI6MjEwNjAxODE2Mn0.zhl-nd806Gs_VGmNg70UEKEWwck-Iielnb6JCD8sRjI';

  Future<LanguageAnalysis> analyze(String text) async {
    final normalized = text.trim();

    if (normalized.isEmpty) {
      throw const LanguageAnalysisException('請先輸入想分析的內容。');
    }

    if (normalized.length > 2000) {
      throw const LanguageAnalysisException('內容太長，請控制在 2000 個字元以內。');
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
            body: jsonEncode({'text': normalized}),
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const LanguageAnalysisException('AI 分析逾時，請稍後再試。');
    } catch (_) {
      throw const LanguageAnalysisException('目前無法連線到 AI 服務，請稍後再試。');
    }

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(response.body);
      payload = decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
    } catch (_) {
      throw const LanguageAnalysisException('AI 服務回傳了無法讀取的內容。');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = payload['error'] as String?;
      final message = payload['message'] as String?;

      if (code == 'AI_BACKEND_NOT_CONFIGURED') {
        throw const LanguageAnalysisException(
          'AI 後端尚未設定完成，請先設定 OpenAI API Key。',
        );
      }

      throw LanguageAnalysisException(
        message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'AI 分析失敗，請稍後再試。',
      );
    }

    final rawAnalysis = payload['analysis'];
    if (rawAnalysis is! Map) {
      throw const LanguageAnalysisException('AI 分析結果格式不正確。');
    }

    final analysis = LanguageAnalysis.fromJson(
      Map<String, dynamic>.from(rawAnalysis),
    );

    if (analysis.chinese.isEmpty ||
        analysis.english.isEmpty ||
        analysis.tagalog.isEmpty) {
      throw const LanguageAnalysisException('AI 分析結果不完整，請再試一次。');
    }

    return analysis;
  }
}
