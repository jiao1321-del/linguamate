import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learner_memory_profile.dart';

class LearnerMemoryStore {
  static const _key = 'learner_memory_profile_v138';

  const LearnerMemoryStore();

  Future<LearnerMemoryProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) {
      return const LearnerMemoryProfile.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const LearnerMemoryProfile.empty();
      return LearnerMemoryProfile.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return const LearnerMemoryProfile.empty();
    }
  }

  Future<void> save(LearnerMemoryProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
