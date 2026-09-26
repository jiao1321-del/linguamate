import 'dart:convert';

import '../models/learning_item.dart';

class BackupCodec {
  static const prefix = 'LINGUAMATE_BACKUP_V1:';

  static String encode(List<LearningItem> items) {
    final payload = <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };

    final json = jsonEncode(payload);
    final encoded = base64UrlEncode(utf8.encode(json));
    return '$prefix$encoded';
  }

  static List<LearningItem> decode(String backupCode) {
    final normalized = backupCode.trim();

    if (!normalized.startsWith(prefix)) {
      throw const FormatException('不是有效的 LinguaMate 備份碼。');
    }

    final encoded = normalized.substring(prefix.length);
    if (encoded.isEmpty) {
      throw const FormatException('備份碼內容為空。');
    }

    try {
      final decodedJson = utf8.decode(base64Url.decode(encoded));
      final payload = jsonDecode(decodedJson);

      if (payload is! Map<String, dynamic>) {
        throw const FormatException('備份格式不正確。');
      }

      if (payload['version'] != 1) {
        throw const FormatException('不支援的備份版本。');
      }

      final rawItems = payload['items'];
      if (rawItems is! List) {
        throw const FormatException('備份內沒有學習資料。');
      }

      final items = rawItems
          .map(
            (item) => LearningItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);

      final ids = <String>{};
      for (final item in items) {
        if (!ids.add(item.id)) {
          throw const FormatException('備份內含重複資料。');
        }
      }

      final sorted = [...items]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('備份碼已損壞或內容無法讀取。');
    }
  }
}
