import 'package:flutter_test/flutter_test.dart';
import 'package:linguamate/main.dart';

void main() {
  testWidgets('LinguaMate renders', (tester) async {
    await tester.pumpWidget(const LinguaMateApp());
    expect(find.text('LinguaMate'), findsOneWidget);
  });
}
