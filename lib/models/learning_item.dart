class LearningItem {
  static const uncategorized = '未分類';

  final String id;
  final String text;
  final DateTime createdAt;
  final String category;

  const LearningItem({
    required this.id,
    required this.text,
    required this.createdAt,
    this.category = uncategorized,
  });

  LearningItem copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    String? category,
  }) {
    return LearningItem(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
    };
  }

  factory LearningItem.fromJson(Map<String, dynamic> json) {
    return LearningItem(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: (json['category'] as String?) ?? uncategorized,
    );
  }
}
