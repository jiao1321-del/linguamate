class CloudPayloadMerger {
  const CloudPayloadMerger._();

  static Map<String, dynamic> merge(
    Map<String, dynamic> local,
    Map<String, dynamic>? cloud,
  ) {
    if (cloud == null || cloud.isEmpty) {
      return {
        ...local,
        'schemaVersion': 146,
        'syncedAt': DateTime.now().toUtc().toIso8601String(),
      };
    }

    final localTime = _date(local['syncedAt']);
    final cloudTime = _date(cloud['syncedAt']);
    final cloudIsNewer = cloudTime.isAfter(localTime);

    return <String, dynamic>{
      'schemaVersion': 146,
      'savedItems': _mergeList(local['savedItems'], cloud['savedItems'], 'id'),
      'weaknesses':
          _mergeList(local['weaknesses'], cloud['weaknesses'], 'category'),
      'mistakes':
          _mergeList(local['mistakes'], cloud['mistakes'], 'taskId'),
      'abilities':
          _mergeList(local['abilities'], cloud['abilities'], 'key'),
      'trainingHistory': _mergeHistory(
        local['trainingHistory'],
        cloud['trainingHistory'],
      ),
      'dailyGoal': cloudIsNewer
          ? (cloud['dailyGoal'] ?? local['dailyGoal'])
          : (local['dailyGoal'] ?? cloud['dailyGoal']),
      'speakingHistory': _mergeList(
        local['speakingHistory'],
        cloud['speakingHistory'],
        'id',
      ),
      'courseCompleted': _mergeStrings(
        local['courseCompleted'],
        cloud['courseCompleted'],
      ),
      'roadmapCompleted': _mergeStrings(
        local['roadmapCompleted'],
        cloud['roadmapCompleted'],
      ),
      'campaignCompleted': _mergeStrings(
        local['campaignCompleted'],
        cloud['campaignCompleted'],
      ),
      'trainingTelemetry': _mergeList(
        local['trainingTelemetry'],
        cloud['trainingTelemetry'],
        'id',
      ),
      'learnerMemory': cloudIsNewer
          ? (cloud['learnerMemory'] ?? local['learnerMemory'])
          : (local['learnerMemory'] ?? cloud['learnerMemory']),
      'roadmapGoal': cloudIsNewer
          ? (cloud['roadmapGoal'] ?? local['roadmapGoal'])
          : (local['roadmapGoal'] ?? cloud['roadmapGoal']),
      'chatState': cloudIsNewer
          ? (cloud['chatState'] ?? local['chatState'])
          : (local['chatState'] ?? cloud['chatState']),
      'syncedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static List<Map<String, dynamic>> _mergeList(
    dynamic a,
    dynamic b,
    String key,
  ) {
    final byKey = <String, Map<String, dynamic>>{};
    for (final raw in <dynamic>[a, b]) {
      if (raw is! List) continue;
      for (final item in raw.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final identity = (map[key] ?? '').toString().trim();
        if (identity.isEmpty) continue;
        final existing = byKey[identity];
        if (existing == null || _prefer(map, existing)) {
          byKey[identity] = map;
        }
      }
    }
    final values = byKey.values.toList(growable: false);
    values.sort((x, y) => _latestDate(y).compareTo(_latestDate(x)));
    return values;
  }

  static List<Map<String, dynamic>> _mergeHistory(dynamic a, dynamic b) {
    final result = <String, Map<String, dynamic>>{};
    for (final raw in <dynamic>[a, b]) {
      if (raw is! List) continue;
      for (final item in raw.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final completedAt = (map['completedAt'] ?? '').toString();
        final dateKey = (map['dateKey'] ?? '').toString();
        final identity = '$dateKey|$completedAt';
        if (identity == '|') continue;
        result[identity] = map;
      }
    }
    final values = result.values.toList(growable: false);
    values.sort((x, y) => _latestDate(y).compareTo(_latestDate(x)));
    return values.length <= 180 ? values : values.take(180).toList();
  }

  static List<String> _mergeStrings(dynamic a, dynamic b) {
    final values = <String>{};
    for (final raw in <dynamic>[a, b]) {
      if (raw is List) {
        values.addAll(
          raw.whereType<String>().map((item) => item.trim()).where(
                (item) => item.isNotEmpty,
              ),
        );
      }
    }
    final sorted = values.toList()..sort();
    return sorted;
  }

  static bool _prefer(
    Map<String, dynamic> candidate,
    Map<String, dynamic> existing,
  ) {
    final candidateDate = _latestDate(candidate);
    final existingDate = _latestDate(existing);
    if (candidateDate != existingDate) {
      return candidateDate.isAfter(existingDate);
    }

    final candidateCount = _largestCounter(candidate);
    final existingCount = _largestCounter(existing);
    return candidateCount >= existingCount;
  }

  static int _largestCounter(Map<String, dynamic> value) {
    const keys = <String>[
      'attempts',
      'reviewCount',
      'wrongCount',
      'count',
      'score',
    ];
    var best = 0;
    for (final key in keys) {
      final candidate = (value[key] as num?)?.toInt() ?? 0;
      if (candidate > best) best = candidate;
    }
    return best;
  }

  static DateTime _latestDate(Map<String, dynamic> value) {
    const keys = <String>[
      'updatedAt',
      'recordedAt',
      'lastPracticedAt',
      'lastReviewedAt',
      'lastWrongAt',
      'lastCorrectAt',
      'completedAt',
      'lastSeenAt',
      'createdAt',
    ];
    var best = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    for (final key in keys) {
      final candidate = _date(value[key]);
      if (candidate.isAfter(best)) best = candidate;
    }
    return best;
  }

  static DateTime _date(dynamic raw) {
    if (raw is! String || raw.trim().isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.tryParse(raw)?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
