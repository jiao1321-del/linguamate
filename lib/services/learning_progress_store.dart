import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_training.dart';

class LearningProgressStore {
  static const _storageKey = 'learning_progress_history_v1';

  const LearningProgressStore();

  Future<List<DailyTrainingSummary>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final items = decoded
          .whereType<Map>()
          .map(
            (item) => DailyTrainingSummary.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.dateKey.isNotEmpty)
          .toList(growable: false);

      return _sorted(items);
    } catch (_) {
      return const [];
    }
  }

  Future<List<DailyTrainingSummary>> append(
    DailyTrainingSummary summary,
  ) async {
    final current = await load();
    final updated = [...current, summary];

    final capped = updated.length <= 90
        ? updated
        : updated.sublist(updated.length - 90);
    final sorted = _sorted(capped);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(sorted.map((item) => item.toJson()).toList()),
    );
    return sorted;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  List<DailyTrainingSummary> _sorted(
    List<DailyTrainingSummary> items,
  ) {
    final sorted = [...items];
    sorted.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return sorted;
  }
}
