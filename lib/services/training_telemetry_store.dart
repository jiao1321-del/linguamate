import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_telemetry.dart';

class TrainingTelemetryStore {
  static const _key = 'training_telemetry_v142';

  const TrainingTelemetryStore();

  Future<List<TrainingTelemetry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final items = decoded
          .whereType<Map>()
          .map(
            (item) => TrainingTelemetry.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);
      items.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<List<TrainingTelemetry>> append(
    TrainingTelemetry item,
  ) async {
    final current = await load();
    final updated = [item, ...current];
    final capped =
        updated.length <= 500 ? updated : updated.take(500).toList();
    await replace(capped);
    return capped;
  }

  Future<void> replace(List<TrainingTelemetry> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
