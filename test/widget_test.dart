import 'package:flutter_test/flutter_test.dart';
import 'package:linguamate/main.dart';
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

  testWidgets('saved sentence appears in collection', (tester) async {
    await tester.pumpWidget(const LinguaMateApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('學習'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(EditableText),
      'This is my saved sentence.',
    );
    await tester.tap(find.text('加入我的學習'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();

    expect(find.text('This is my saved sentence.'), findsOneWidget);
  });
}
