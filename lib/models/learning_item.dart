class LearningItem {
  static const uncategorized = '未分類';
  static const reviewIntervalsInDays = <int>[1, 3, 7, 14, 30];

  final String id;
  final String text;
  final DateTime createdAt;
  final String category;
  final int reviewLevel;
  final int reviewCount;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;

  const LearningItem({
    required this.id,
    required this.text,
    required this.createdAt,
    this.category = uncategorized,
    this.reviewLevel = 0,
    this.reviewCount = 0,
    this.lastReviewedAt,
    this.nextReviewAt,
  });

  bool isDue(DateTime now) {
    final dueAt = nextReviewAt;
    return dueAt == null || !dueAt.isAfter(now);
  }

  LearningItem reviewed({
    required bool remembered,
    required DateTime now,
  }) {
    if (!remembered) {
      return copyWith(
        reviewLevel: 0,
        reviewCount: reviewCount + 1,
        lastReviewedAt: now,
        nextReviewAt: now,
      );
    }

    final nextLevel =
        (reviewLevel + 1).clamp(1, reviewIntervalsInDays.length);
    final intervalDays = reviewIntervalsInDays[nextLevel - 1];

    return copyWith(
      reviewLevel: nextLevel,
      reviewCount: reviewCount + 1,
      lastReviewedAt: now,
      nextReviewAt: now.add(Duration(days: intervalDays)),
    );
  }

  LearningItem copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    String? category,
    int? reviewLevel,
    int? reviewCount,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
  }) {
    return LearningItem(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      reviewLevel: reviewLevel ?? this.reviewLevel,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'reviewLevel': reviewLevel,
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'nextReviewAt': nextReviewAt?.toIso8601String(),
    };
  }

  factory LearningItem.fromJson(Map<String, dynamic> json) {
    return LearningItem(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: (json['category'] as String?) ?? uncategorized,
      reviewLevel: (json['reviewLevel'] as num?)?.toInt() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      lastReviewedAt: _parseOptionalDate(json['lastReviewedAt']),
      nextReviewAt: _parseOptionalDate(json['nextReviewAt']),
    );
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
