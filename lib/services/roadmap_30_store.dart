import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Roadmap30Store {
  static const _goalKey = 'roadmap_30_goal_v143';
  static const _completedKey = 'roadmap_30_completed_v143';

  const Roadmap30Store();

  Future<String> loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_goalKey) ?? '日常英文';
  }

  Future<void> saveGoal(String goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalKey, goal);
  }

  Future<Set<String>> loadCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_completedKey);
    if (raw == null || raw.trim().isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<Set<String>> complete({
    required String goal,
    required int day,
  }) async {
    final current = await loadCompleted();
    current.add('$goal::$day');
    await replace(current);
    return current;
  }

  Future<void> replace(Set<String> completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_completedKey, jsonEncode(completed.toList()));
  }
}
