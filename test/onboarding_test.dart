import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguamate/screens/onboarding_screen.dart';
import 'package:linguamate/services/onboarding_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('V1.47 onboarding store remembers setup and completion', () async {
    const store = OnboardingStore();

    expect(await store.isCompleted(), isFalse);

    await store.complete(
      language: 'Taglish',
      goal: 'Taglish',
    );

    expect(await store.isCompleted(), isTrue);
    expect(await store.loadLanguage(), 'Taglish');
    expect(await store.loadGoal(), 'Taglish');

    await store.reset();
    expect(await store.isCompleted(), isFalse);
  });

  testWidgets('V1.47 family onboarding covers install cloud setup and lesson',
      (tester) async {
    String? finishedLanguage;
    String? finishedGoal;
    var cloudOpened = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onOpenCloud: () => cloudOpened++,
          onFinish: (language, goal) async {
            finishedLanguage = language;
            finishedGoal = goal;
          },
          onSkip: () async {},
        ),
      ),
    );

    expect(find.text('歡迎來到 LinguaMate'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('先把 LinguaMate 放到桌面'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('每個人都用自己的帳號'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-open-cloud')));
    await tester.pump();
    expect(cloudOpened, 1);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('設定你的學習方向'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('onboarding-language-Tagalog')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('準備好了！'), findsOneWidget);
    expect(find.textContaining('Tagalog'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();

    expect(finishedLanguage, 'Tagalog');
    expect(finishedGoal, '日常英文');
  });

  testWidgets('V1.47 onboarding can be skipped', (tester) async {
    var skipped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onOpenCloud: () {},
          onFinish: (_, __) async {},
          onSkip: () async => skipped = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();

    expect(skipped, isTrue);
  });
}
