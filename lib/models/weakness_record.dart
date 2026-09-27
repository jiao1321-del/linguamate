class WeaknessRecord {
  final String category;
  final int count;
  final String example;
  final String correction;
  final String explanation;
  final DateTime lastSeenAt;

  const WeaknessRecord({
    required this.category,
    required this.count,
    required this.example,
    required this.correction,
    required this.explanation,
    required this.lastSeenAt,
  });

  WeaknessRecord copyWith({
    int? count,
    String? example,
    String? correction,
    String? explanation,
    DateTime? lastSeenAt,
  }) {
    return WeaknessRecord(
      category: category,
      count: count ?? this.count,
      example: example ?? this.example,
      correction: correction ?? this.correction,
      explanation: explanation ?? this.explanation,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'count': count,
        'example': example,
        'correction': correction,
        'explanation': explanation,
        'lastSeenAt': lastSeenAt.toIso8601String(),
      };

  factory WeaknessRecord.fromJson(Map<String, dynamic> json) {
    return WeaknessRecord(
      category: (json['category'] as String? ?? '自然用法').trim(),
      count: json['count'] as int? ?? 1,
      example: (json['example'] as String? ?? '').trim(),
      correction: (json['correction'] as String? ?? '').trim(),
      explanation: (json['explanation'] as String? ?? '').trim(),
      lastSeenAt:
          DateTime.tryParse(json['lastSeenAt'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
