import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_item.dart';

class LearningStore {
  static const _storageKey = 'learning_items_v1';

  Future<List<LearningItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_storageKey) ?? const <String>[];

    final items = <LearningItem>[];
    for (final rawItem in rawItems) {
      try {
        final decoded = jsonDecode(rawItem) as Map<String, dynamic>;
        items.add(LearningItem.fromJson(decoded));
      } catch (_) {
        // Ignore corrupted legacy entries instead of blocking the app.
      }
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> saveItems(List<LearningItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_storageKey, encoded);
  }
}
