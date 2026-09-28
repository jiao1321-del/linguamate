import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cloud_session.dart';

class CloudSyncException implements Exception {
  final String message;

  const CloudSyncException(this.message);

  @override
  String toString() => message;
}

class CloudSyncService {
  static const _baseUrl = 'https://svzsynadhzvflauxppwn.supabase.co';
  static const _publishableKey =
      'sb_publishable_UoxuXbXG8Qvy0Snte4jmPQ_IIPI-IzR';
  static const _sessionKey = 'linguamate_cloud_session_v136';

  const CloudSyncService();

  Future<CloudSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final session = CloudSession.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      return session.isValid ? session : null;
    } catch (_) {
      return null;
    }
  }

  Future<CloudSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/v1/token?grant_type=password'),
      headers: const {
        'apikey': _publishableKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );
    return _sessionFromResponse(response);
  }

  Future<CloudSession?> signUp({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/v1/signup'),
      headers: const {
        'apikey': _publishableKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudSyncException(_errorMessage(response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const CloudSyncException('註冊回應格式異常。');
    }
    final data = Map<String, dynamic>.from(decoded);
    final accessToken = (data['access_token'] as String? ?? '').trim();
    if (accessToken.isEmpty) {
      return null;
    }
    return _saveParsedSession(data);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> upload({
    required CloudSession session,
    required Map<String, dynamic> payload,
  }) async {
    var active = session;
    var response = await _upload(active, payload);
    if (response.statusCode == 401) {
      active = await refresh(session);
      response = await _upload(active, payload);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudSyncException(_errorMessage(response));
    }
  }

  Future<Map<String, dynamic>?> download(
    CloudSession session,
  ) async {
    var active = session;
    var response = await _download(active);
    if (response.statusCode == 401) {
      active = await refresh(session);
      response = await _download(active);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudSyncException(_errorMessage(response));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) return null;
    final first = decoded.first;
    if (first is! Map) return null;
    final payload = first['payload'];
    return payload is Map
        ? Map<String, dynamic>.from(payload)
        : null;
  }

  Future<CloudSession> refresh(CloudSession session) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/v1/token?grant_type=refresh_token'),
      headers: const {
        'apikey': _publishableKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'refresh_token': session.refreshToken}),
    );
    return _sessionFromResponse(response);
  }

  Future<http.Response> _upload(
    CloudSession session,
    Map<String, dynamic> payload,
  ) {
    return http.post(
      Uri.parse(
        '$_baseUrl/rest/v1/learning_cloud_state?on_conflict=user_id',
      ),
      headers: {
        'apikey': _publishableKey,
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      },
      body: jsonEncode({
        'user_id': session.userId,
        'payload': payload,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  Future<http.Response> _download(CloudSession session) {
    final userId = Uri.encodeQueryComponent(session.userId);
    return http.get(
      Uri.parse(
        '$_baseUrl/rest/v1/learning_cloud_state'
        '?select=payload,updated_at&user_id=eq.$userId&limit=1',
      ),
      headers: {
        'apikey': _publishableKey,
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );
  }

  CloudSession _sessionFromResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CloudSyncException(_errorMessage(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const CloudSyncException('登入回應格式異常。');
    }
    return _saveParsedSession(Map<String, dynamic>.from(decoded));
  }

  CloudSession _saveParsedSession(Map<String, dynamic> data) {
    final user = data['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user) : const {};
    final session = CloudSession(
      accessToken: (data['access_token'] as String? ?? '').trim(),
      refreshToken: (data['refresh_token'] as String? ?? '').trim(),
      userId: (userMap['id'] as String? ?? '').trim(),
      email: (userMap['email'] as String? ?? '').trim(),
    );
    if (!session.isValid) {
      throw const CloudSyncException('登入資訊不完整，請重新登入。');
    }
    unawaited(_persistSession(session));
    return session;
  }

  Future<void> _persistSession(CloudSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final message = decoded['msg'] ??
            decoded['message'] ??
            decoded['error_description'] ??
            decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}
    return '雲端服務暫時無法完成操作（HTTP ${response.statusCode}）。';
  }
}
