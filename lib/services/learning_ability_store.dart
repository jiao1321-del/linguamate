import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_training.dart';
import '../models/learning_ability.dart';

class LearningAbilityStore {
  static const _storageKey = 'learning_ability_v1';

  const LearningAbilityStore();

  Future<List<LearningAbilityRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final records = decoded
          .whereType<Map>()
          .map(
            (item) => LearningAbilityRecord.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(
            (item) =>
                item.key.isNotEmpty &&
                item.label.isNotEmpty &&
                item.attempts > 0,
          )
          .toList(growable: false);

      return _sorted(records);
    } catch (_) {
      return const [];
    }
  }

  Future<List<LearningAbilityRecord>> recordResult({
    required DailyTrainingTask task,
    required bool correct,
    DateTime? now,
  }) async {
    final timestamp = now ?? DateTime.now();
    final current = await load();
    final identity = LearningAbilityRecord.identityFor(task);
    final index = current.indexWhere((item) => item.key == identity.key);
    final updated = [...current];

    if (index >= 0) {
      updated[index] = updated[index].recordResult(
        correct: correct,
        now: timestamp,
      );
    } else {
      updated.add(
        LearningAbilityRecord.fromTask(
          task,
          correct: correct,
          now: timestamp,
        ),
      );
    }

    final sorted = _sorted(updated);
    await _save(sorted);
    return sorted;
  }

  Future<void> replace(List<LearningAbilityRecord> records) =>
      _save(_sorted(records));

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save(List<LearningAbilityRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  }

  List<LearningAbilityRecord> _sorted(
    List<LearningAbilityRecord> records,
  ) {
    final report = LearningAbilityReport(records: records);
    return report.ranked;
  }
}
