import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_training.dart';

class DailyTrainingStore {
  static const _storageKey = 'daily_training_summary_v1';

  const DailyTrainingStore();

  Future<DailyTrainingSummary?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return DailyTrainingSummary.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(DailyTrainingSummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(summary.toJson()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
