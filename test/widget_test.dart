import 'package:flutter_test/flutter_test.dart';
import 'package:linguamate/main.dart';
import 'package:linguamate/models/learning_item.dart';
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

  test('LearningStore persists and removes saved sentences', () async {
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
    );

    await store.saveItems([first, second]);
    final loaded = await store.loadItems();

    expect(loaded, hasLength(2));

    final remaining = loaded.where((item) => item.id != first.id).toList();
    await store.saveItems(remaining);

    final reloaded = await store.loadItems();
    expect(reloaded, hasLength(1));
    expect(reloaded.first.id, second.id);
    expect(reloaded.first.text, second.text);
  });
}
