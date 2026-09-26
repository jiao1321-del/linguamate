import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguamate/main.dart';
import 'package:linguamate/models/learning_item.dart';
import 'package:linguamate/screens/saved_screen.dart';
import 'package:linguamate/services/learning_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LinguaMate renders', (tester) async {
    await tester.pumpWidget(const LinguaMateApp());
    await tester.pumpAndSettle();

    expect(find.text('LinguaMate'), findsOneWidget);
  });

  testWidgets('SavedScreen filters saved sentences by text and category',
      (tester) async {
    final items = [
      LearningItem(
        id: '1',
        text: 'I want to learn Tagalog.',
        createdAt: DateTime(2026, 9, 27),
        category: '工作',
      ),
      LearningItem(
        id: '2',
        text: 'I like it.',
        createdAt: DateTime(2026, 9, 27),
        category: '生活',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedScreen(
            items: items,
            isLoading: false,
            onDelete: (_) async {},
            onCategoryChanged: (_, __) async {},
          ),
        ),
      ),
    );

    expect(find.text('2 句'), findsOneWidget);
    expect(find.text('I want to learn Tagalog.'), findsOneWidget);
    expect(find.text('I like it.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, '工作'));
    await tester.pump();

    expect(find.text('1/2 句'), findsOneWidget);
    expect(find.text('I want to learn Tagalog.'), findsOneWidget);
    expect(find.text('I like it.'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, '全部'));
    await tester.pump();

    await tester.enterText(
      find.byType(TextField),
      'like',
    );
    await tester.pump();

    expect(find.text('1/2 句'), findsOneWidget);
    expect(find.text('I want to learn Tagalog.'), findsNothing);
    expect(find.text('I like it.'), findsOneWidget);
  });

  test('LearningItem loads legacy saved data as uncategorized', () {
    final item = LearningItem.fromJson(
      jsonDecode(
        '{"id":"legacy","text":"Old sentence","createdAt":"2026-09-27T00:00:00.000"}',
      ) as Map<String, dynamic>,
    );

    expect(item.category, LearningItem.uncategorized);
  });

  test('LearningStore persists category updates and deletion', () async {
    final store = LearningStore();
    final first = LearningItem(
      id: 'test-1',
      text: 'This is my first saved sentence.',
      createdAt: DateTime(2026, 9, 27),
    );
    final second = LearningItem(
      id: 'test-2',
      text: 'This sentence should remain.',
      createdAt: DateTime(2026, 9, 28),
      category: '工作',
    );

    await store.saveItems([first, second]);
    final loaded = await store.loadItems();

    expect(loaded, hasLength(2));

    final remaining = loaded
        .where((item) => item.id != first.id)
        .map((item) => item.copyWith(category: '生活'))
        .toList();

    await store.saveItems(remaining);

    final reloaded = await store.loadItems();
    expect(reloaded, hasLength(1));
    expect(reloaded.first.id, second.id);
    expect(reloaded.first.category, '生活');
  });
}
