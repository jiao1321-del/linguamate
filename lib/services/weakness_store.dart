import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/weakness_record.dart';

class WeaknessStore {
  static const _storageKey = 'weakness_records_v1';

  const WeaknessStore();

  Future<List<WeaknessRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final records = decoded
          .whereType<Map>()
          .map(
            (item) => WeaknessRecord.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.category.isNotEmpty)
          .toList(growable: false);

      return _sorted(records);
    } catch (_) {
      return const [];
    }
  }

  Future<List<WeaknessRecord>> record({
    required String category,
    required String example,
    required String correction,
    required String explanation,
    DateTime? now,
  }) async {
    final current = await load();
    final timestamp = now ?? DateTime.now();

    final existingIndex =
        current.indexWhere((item) => item.category == category);
    final updated = [...current];

    if (existingIndex >= 0) {
      final existing = updated[existingIndex];
      updated[existingIndex] = existing.copyWith(
        count: existing.count + 1,
        example: example.trim(),
        correction: correction.trim(),
        explanation: explanation.trim(),
        lastSeenAt: timestamp,
      );
    } else {
      updated.add(
        WeaknessRecord(
          category: category,
          count: 1,
          example: example.trim(),
          correction: correction.trim(),
          explanation: explanation.trim(),
          lastSeenAt: timestamp,
        ),
      );
    }

    final sorted = _sorted(updated);
    await _save(sorted);
    return sorted;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save(List<WeaknessRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  }

  List<WeaknessRecord> _sorted(List<WeaknessRecord> records) {
    final sorted = [...records];
    sorted.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return b.lastSeenAt.compareTo(a.lastSeenAt);
    });
    return sorted;
  }
}
