import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_training.dart';
import '../models/mistake_record.dart';

class MistakeStore {
  static const _storageKey = 'mistake_records_v1';

  const MistakeStore();

  Future<List<MistakeRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final items = decoded
          .whereType<Map>()
          .map(
            (item) => MistakeRecord.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (item) =>
                item.taskId.isNotEmpty &&
                item.prompt.isNotEmpty &&
                item.answer.isNotEmpty,
          )
          .toList(growable: false);
      return _sorted(items);
    } catch (_) {
      return const [];
    }
  }

  Future<List<MistakeRecord>> recordResult({
    required DailyTrainingTask task,
    required bool correct,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final current = await load();
    final index = current.indexWhere((item) => item.taskId == task.id);
    final updated = [...current];

    if (index >= 0) {
      updated[index] = updated[index].recordResult(
        correct: correct,
        now: timestamp,
      );
    } else if (!correct) {
      updated.add(
        MistakeRecord.fromTask(
          task,
          now: timestamp,
        ),
      );
    } else {
      return current;
    }

    final sorted = _sorted(updated);
    await _save(sorted);
    return sorted;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  List<MistakeRecord> active(List<MistakeRecord> items) {
    return items.where((item) => item.isActive).toList(growable: false);
  }

  Future<void> _save(List<MistakeRecord> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  List<MistakeRecord> _sorted(List<MistakeRecord> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }
      final byWrongCount = b.wrongCount.compareTo(a.wrongCount);
      if (byWrongCount != 0) return byWrongCount;
      return b.lastWrongAt.compareTo(a.lastWrongAt);
    });
    return sorted;
  }
}
