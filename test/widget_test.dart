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

  test('LearningStore persists saved sentences', () async {
    final store = LearningStore();
    final item = LearningItem(
      id: 'test-1',
      text: 'This is my saved sentence.',
      createdAt: DateTime(2026, 9, 27),
    );

    await store.saveItems([item]);
    final loaded = await store.loadItems();

    expect(loaded, hasLength(1));
    expect(loaded.first.id, item.id);
    expect(loaded.first.text, item.text);
    expect(loaded.first.createdAt, item.createdAt);
  });
}
