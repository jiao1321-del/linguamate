import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CourseProgressStore {
  static const _key = 'course_progress_v135';

  const CourseProgressStore();

  Future<Set<String>> loadCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<Set<String>> complete(String chapterId) async {
    final current = await loadCompleted();
    current.add(chapterId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(current.toList()));
    return current;
  }

  Future<void> replace(Set<String> completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(completed.toList()));
  }
}
