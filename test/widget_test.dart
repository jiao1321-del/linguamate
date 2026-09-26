import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguamate/main.dart';
import 'package:linguamate/models/learning_item.dart';
import 'package:linguamate/screens/home_screen.dart';
import 'package:linguamate/screens/review_screen.dart';
import 'package:linguamate/screens/saved_screen.dart';
import 'package:linguamate/services/backup_codec.dart';
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

  testWidgets('HomeScreen shows real due-review state', (tester) async {
    final now = DateTime.now();
    final items = [
      LearningItem(
        id: '1',
        text: 'I want to learn Tagalog.',
        createdAt: now,
        category: 'Tagalog',
      ),
      LearningItem(
        id: '2',
        text: 'I like it.',
        createdAt: now.subtract(const Duration(days: 1)),
        nextReviewAt: now.add(const Duration(days: 3)),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            items: items,
            isLoading: false,
            onStartReview: () {},
          ),
        ),
      ),
    );

    expect(find.text('收藏總數'), findsOneWidget);
    expect(find.text('待複習'), findsOneWidget);
    expect(find.text('今日新增'), findsOneWidget);
    expect(find.text('未分類'), findsOneWidget);
    expect(find.text('複習 1 個到期句子'), findsOneWidget);
    expect(find.text('開始今日複習'), findsOneWidget);
    expect(find.text('48m'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('I want to learn Tagalog.'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('I want to learn Tagalog.'), findsOneWidget);
  });

  testWidgets('ReviewScreen persists remember result and advances',
      (tester) async {
    final calls = <String>[];
    final items = [
      LearningItem(
        id: '1',
        text: 'I want to learn Tagalog.',
        createdAt: DateTime(2026, 9, 27),
        category: 'Tagalog',
      ),
      LearningItem(
        id: '2',
        text: 'I like it.',
        createdAt: DateTime(2026, 9, 26),
        category: '生活',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewScreen(
          items: items,
          onReviewResult: (id, remembered) async {
            calls.add('$id:$remembered');
          },
        ),
      ),
    );

    expect(find.text('0 / 2'), findsOneWidget);
    expect(find.text('I want to learn Tagalog.'), findsOneWidget);
    expect(find.text('點一下卡片查看提示'), findsOneWidget);

    await tester.tap(find.text('I want to learn Tagalog.'));
    await tester.pumpAndSettle();

    expect(find.text('Tagalog'), findsOneWidget);
    expect(find.text('已複習 0 次 · 階段 0'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '記得'));
    await tester.pumpAndSettle();

    expect(calls, contains('1:true'));
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('I like it.'), findsOneWidget);
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

  test('LearningItem loads legacy data with default review state', () {
    final item = LearningItem.fromJson(
      jsonDecode(
        '{"id":"legacy","text":"Old sentence","createdAt":"2026-09-27T00:00:00.000"}',
      ) as Map<String, dynamic>,
    );

    expect(item.category, LearningItem.uncategorized);
    expect(item.reviewLevel, 0);
    expect(item.reviewCount, 0);
    expect(item.lastReviewedAt, isNull);
    expect(item.nextReviewAt, isNull);
  });

  test('LearningItem schedules 1, 3 days then resets on review again', () {
    final start = DateTime.utc(2026, 9, 27, 1);
    final initial = LearningItem(
      id: 'srs',
      text: 'Remember me.',
      createdAt: start,
    );

    final first = initial.reviewed(
      remembered: true,
      now: start,
    );
    expect(first.reviewLevel, 1);
    expect(first.reviewCount, 1);
    expect(first.nextReviewAt, start.add(const Duration(days: 1)));
    expect(first.isDue(start), isFalse);

    final secondNow = first.nextReviewAt!;
    final second = first.reviewed(
      remembered: true,
      now: secondNow,
    );
    expect(second.reviewLevel, 2);
    expect(second.reviewCount, 2);
    expect(second.nextReviewAt, secondNow.add(const Duration(days: 3)));

    final reset = second.reviewed(
      remembered: false,
      now: secondNow,
    );
    expect(reset.reviewLevel, 0);
    expect(reset.reviewCount, 3);
    expect(reset.nextReviewAt, secondNow);
    expect(reset.isDue(secondNow), isTrue);
  });

  test('BackupCodec preserves learning and SRS data', () {
    final now = DateTime.utc(2026, 9, 27, 2);
    final items = [
      LearningItem(
        id: 'backup-1',
        text: 'I will reply later.',
        createdAt: now,
        category: 'English',
        reviewLevel: 2,
        reviewCount: 3,
        lastReviewedAt: now,
        nextReviewAt: now.add(const Duration(days: 3)),
      ),
    ];

    final code = BackupCodec.encode(items);
    expect(code, startsWith(BackupCodec.prefix));

    final restored = BackupCodec.decode(code);
    expect(restored, hasLength(1));
    expect(restored.first.id, 'backup-1');
    expect(restored.first.text, 'I will reply later.');
    expect(restored.first.category, 'English');
    expect(restored.first.reviewLevel, 2);
    expect(restored.first.reviewCount, 3);
    expect(restored.first.lastReviewedAt, now);
    expect(
      restored.first.nextReviewAt,
      now.add(const Duration(days: 3)),
    );
  });

  test('BackupCodec rejects invalid backup codes', () {
    expect(
      () => BackupCodec.decode('not-a-linguamate-backup'),
      throwsFormatException,
    );
  });

  test('LearningStore persists review progress, category and deletion', () async {
    final store = LearningStore();
    final now = DateTime.utc(2026, 9, 27, 1);
    final first = LearningItem(
      id: 'test-1',
      text: 'This is my first saved sentence.',
      createdAt: now,
    );
    final second = LearningItem(
      id: 'test-2',
      text: 'This sentence should remain.',
      createdAt: now.add(const Duration(days: 1)),
      category: '工作',
    ).reviewed(
      remembered: true,
      now: now,
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
    expect(reloaded.first.reviewLevel, 1);
    expect(reloaded.first.reviewCount, 1);
    expect(reloaded.first.nextReviewAt, now.add(const Duration(days: 1)));
  });
}
