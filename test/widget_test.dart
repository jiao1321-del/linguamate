import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguamate/main.dart';
import 'package:linguamate/models/ai_chat_state.dart';
import 'package:linguamate/models/ai_coach_reply.dart';
import 'package:linguamate/models/language_analysis.dart';
import 'package:linguamate/models/learning_item.dart';
import 'package:linguamate/screens/ai_chat_screen.dart';
import 'package:linguamate/screens/home_screen.dart';
import 'package:linguamate/screens/learn_screen.dart';
import 'package:linguamate/screens/learning_card_screen.dart';
import 'package:linguamate/screens/review_screen.dart';
import 'package:linguamate/screens/saved_screen.dart';
import 'package:linguamate/services/ai_chat_store.dart';
import 'package:linguamate/services/backup_codec.dart';
import 'package:linguamate/services/learning_store.dart';
import 'package:linguamate/widgets/gilded_card_icon.dart';
import 'package:linguamate/widgets/shili_coach_avatar.dart';
import 'package:linguamate/widgets/shili_coach_header.dart';
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

  testWidgets('LearnScreen renders dynamic three-language AI analysis',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearnScreen(
            onAnalyze: (text) async => const LanguageAnalysis(
              detectedLanguage: 'English',
              chinese: '我晚點回覆你。',
              english: 'I will reply to you later.',
              tagalog: 'Babalikan kita mamaya.',
              tone: '自然、日常，適合一般聊天。',
              learningPoints: [
                LearningPoint(
                  title: 'reply',
                  explanation: '作為動詞表示「回覆」。',
                ),
                LearningPoint(
                  title: 'mamaya',
                  explanation: 'Tagalog 常見的「稍後、等一下」。',
                ),
              ],
            ),
            onSave: (_, __) async => true,
            onSaved: () {},
          ),
        ),
      ),
    );

    expect(find.text('我晚點回覆你。'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '分析並學習'));
    await tester.pumpAndSettle();

    expect(find.text('偵測語言：English'), findsOneWidget);
    expect(find.text('🇹🇼 中文'), findsOneWidget);
    expect(find.text('我晚點回覆你。'), findsOneWidget);
    expect(find.text('🇺🇸 English'), findsOneWidget);
    expect(find.text('I will reply to you later.'), findsAtLeastNWidgets(1));

    await tester.scrollUntilVisible(
      find.text('🇵🇭 Tagalog / Taglish'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('🇵🇭 Tagalog / Taglish'), findsOneWidget);
    expect(find.text('Babalikan kita mamaya.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('✨ 學習重點'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('✨ 學習重點'), findsOneWidget);
    expect(find.text('reply'), findsOneWidget);
    expect(find.text('mamaya'), findsOneWidget);
  });

  testWidgets('LearnScreen pastes clipboard text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearnScreen(
            onAnalyze: (_) async => const LanguageAnalysis(
              detectedLanguage: 'Tagalog',
              chinese: '你好嗎？',
              english: 'How are you?',
              tagalog: 'Kumusta ka?',
              tone: '自然問候。',
              learningPoints: [],
            ),
            onSave: (_, __) async => true,
            readClipboardText: () async => 'Kumusta ka?',
            onSaved: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, '貼上文字'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'Kumusta ka?');
    expect(find.text('已貼上剪貼簿文字。'), findsOneWidget);
  });

  testWidgets('LearnScreen saves full AI analysis with the sentence',
      (tester) async {
    LanguageAnalysis? savedAnalysis;
    String? savedText;
    var openedSaved = false;

    const analysis = LanguageAnalysis(
      detectedLanguage: 'English',
      chinese: '我晚點回覆你。',
      english: 'I will reply to you later.',
      tagalog: 'Babalikan kita mamaya.',
      tone: '自然、日常。',
      learningPoints: [
        LearningPoint(
          title: 'reply',
          explanation: '回覆。',
        ),
        LearningPoint(
          title: 'mamaya',
          explanation: '稍後。',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearnScreen(
            onAnalyze: (_) async => analysis,
            onSave: (text, result) async {
              savedText = text;
              savedAnalysis = result;
              return true;
            },
            onSaved: () => openedSaved = true,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, '分析並學習'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, '加入我的學習'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, '加入我的學習'));
    await tester.pumpAndSettle();

    expect(savedText, 'I will reply to you later.');
    expect(savedAnalysis?.tagalog, 'Babalikan kita mamaya.');
    expect(savedAnalysis?.learningPoints, hasLength(2));
    expect(openedSaved, isTrue);
  });

  testWidgets('AI chat coach sends message and renders coaching reply',
      (tester) async {
    String? sentMessage;
    String? sentTarget;
    String? sentScenario;
    String? savedLearningText;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatScreen(
            onSend: (message, targetLanguage, scenario, history) async {
              sentMessage = message;
              sentTarget = targetLanguage;
              sentScenario = scenario;
              return const AiCoachReply(
                reply: 'I went to the gym after work. How about you?',
                correction: 'I went to the gym after work today.',
                explanation: '描述今天已經發生的事情時，go 要改成過去式 went。',
                translation: '我下班後去健身房了。你呢？',
              );
            },
            onSaveLearning: (text) async {
              savedLearningText = text;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI 對話教練'), findsOneWidget);
    expect(find.text('汐璃 Shili'), findsOneWidget);
    expect(find.byType(ShiliCoachAvatar), findsAtLeastNWidgets(1));
    final coachPanel = find.byType(ShiliCoachHeader);
    expect(coachPanel, findsOneWidget);
    expect(
      find.descendant(
        of: coachPanel,
        matching: find.byKey(const ValueKey('language-selector')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: coachPanel,
        matching: find.byKey(const ValueKey('scenario-selector')),
      ),
      findsOneWidget,
    );

    final languageDropdown = tester.widget<DropdownButton<String>>(
      find.byKey(const ValueKey('language-selector')),
    );
    final scenarioDropdown = tester.widget<DropdownButton<String>>(
      find.byKey(const ValueKey('scenario-selector')),
    );
    expect(languageDropdown.value, 'English');
    expect(scenarioDropdown.value, '自由對話');

    await tester.tap(find.byKey(const ValueKey('scenario-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('工作職場').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('starter-ideas-button')));
    await tester.pumpAndSettle();
    expect(find.text('話題靈感 · 工作職場'), findsOneWidget);
    expect(find.text('生產線上出現了一個問題。'), findsOneWidget);
    await tester.tap(find.text('There is a problem on the production line.'));
    await tester.pumpAndSettle();

    final starterInput = tester.widget<TextField>(
      find.byKey(const ValueKey('chat-input')),
    );
    expect(
      starterInput.controller!.text,
      'There is a problem on the production line.',
    );

    await tester.enterText(
      find.byType(TextField),
      'Today I go gym after work.',
    );
    await tester.tap(find.byKey(const ValueKey('send-chat-message')));
    await tester.pumpAndSettle();

    expect(sentMessage, 'Today I go gym after work.');
    expect(sentTarget, 'English');
    expect(sentScenario, '工作職場');
    expect(
      find.text('I went to the gym after work. How about you?'),
      findsOneWidget,
    );
    expect(find.text('✨ 更自然的說法'), findsOneWidget);
    expect(find.text('I went to the gym after work today.'), findsOneWidget);
    expect(find.text('💡 學習提示'), findsOneWidget);
    expect(find.text('🇹🇼 中文意思'), findsOneWidget);
    expect(find.byType(ShiliCoachAvatar), findsAtLeastNWidgets(2));

    final saveButton = find.byKey(
      const ValueKey('save-chat-learning-card'),
    );
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedLearningText, 'I went to the gym after work today.');
    expect(find.text('已變成鎏金學習卡並加入收藏 ✨'), findsOneWidget);
  });

  testWidgets('AI chat can send from the keyboard send action',
      (tester) async {
    String? sentMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatScreen(
            onSend: (message, targetLanguage, scenario, history) async {
              sentMessage = message;
              return const AiCoachReply(
                reply: 'Got it.',
                correction: '',
                explanation: '自然回覆。',
                translation: '了解。',
              );
            },
            onSaveLearning: (_) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('chat-input'));
    await tester.enterText(field, 'Can you help me check this issue?');
    await tester.showKeyboard(field);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(sentMessage, 'Can you help me check this issue?');
    expect(find.text('Got it.'), findsOneWidget);
  });

  testWidgets('AI chat sends Traditional Chinese text from dedicated button',
      (tester) async {
    String? sentMessage;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatScreen(
            onSend: (message, targetLanguage, scenario, history) async {
              sentMessage = message;
              return const AiCoachReply(
                reply: 'Got it. What happened on the production line?',
                correction: '',
                explanation: '自然承接對話。',
                translation: '了解。產線上發生了什麼事？',
              );
            },
            onSaveLearning: (_) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.showKeyboard(field);
    const composingText = '無塵室的生產主任，目前剛出產線';
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: composingText,
        selection: TextSelection.collapsed(offset: composingText.length),
        composing: TextRange(start: 14, end: composingText.length),
      ),
    );
    await tester.pump();

    final sendButton =
        find.byKey(const ValueKey('send-chat-message'));
    final gesture = await tester.startGesture(
      tester.getCenter(sendButton),
    );
    await tester.pump();

    // The message must already be dispatched on pointer down, before an iOS
    // keyboard dismissal can move the button and cancel a normal tap.
    expect(sentMessage, '無塵室的生產主任，目前剛出產線');

    // Reproduce the late IME update seen on iPhone PWA: after sending, WebKit
    // can briefly restore the composing text into the controller.
    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('chat-input')),
    );
    input.controller!.value = const TextEditingValue(
      text: composingText,
      selection: TextSelection.collapsed(offset: composingText.length),
      composing: TextRange(start: 14, end: composingText.length),
    );

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(sentMessage, '無塵室的生產主任，目前剛出產線');
    expect(input.controller!.text, isEmpty);
    expect(
      find.text('Got it. What happened on the production line?'),
      findsOneWidget,
    );
  });

  testWidgets('AI chat restores saved conversation and language',
      (tester) async {
    const store = AiChatStore();
    await store.save(
      const AiChatState(
        targetLanguage: 'Tagalog',
        scenario: '旅行',
        messages: [
          AiChatMessage(
            mine: true,
            text: 'Pagod ako today.',
          ),
          AiChatMessage(
            mine: false,
            text: 'Magpahinga ka muna. Kumain ka na ba?',
            reply: AiCoachReply(
              reply: 'Magpahinga ka muna. Kumain ka na ba?',
              correction: '',
              explanation: '「muna」常用來表示「先…一下」。',
              translation: '你先休息一下。你吃飯了嗎？',
            ),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiChatScreen(
            chatStore: store,
            onSend: (_, __, ___, ____) async => const AiCoachReply(
              reply: 'Sige!',
              correction: '',
              explanation: '自然回覆。',
              translation: '好！',
            ),
            onSaveLearning: (_) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final languageDropdown = tester.widget<DropdownButton<String>>(
      find.byKey(const ValueKey('language-selector')),
    );
    expect(languageDropdown.value, 'Tagalog');
    final scenarioDropdown = tester.widget<DropdownButton<String>>(
      find.byKey(const ValueKey('scenario-selector')),
    );
    expect(scenarioDropdown.value, '旅行');
    expect(
      find.text('Magpahinga ka muna. Kumain ka na ba?'),
      findsOneWidget,
    );
    expect(find.byType(ShiliCoachAvatar), findsAtLeastNWidgets(2));
  });

  test('AiChatStore persists and clears conversation state', () async {
    const store = AiChatStore();
    const state = AiChatState(
      targetLanguage: 'Taglish',
      scenario: '日常生活',
      messages: [
        AiChatMessage(
          mine: true,
          text: 'Busy ako today.',
        ),
        AiChatMessage(
          mine: false,
          text: 'Take a short break muna.',
          reply: AiCoachReply(
            reply: 'Take a short break muna.',
            correction: '',
            explanation: '自然的 Taglish 表達。',
            translation: '先稍微休息一下。',
          ),
        ),
      ],
    );

    await store.save(state);
    final loaded = await store.load();

    expect(loaded?.targetLanguage, 'Taglish');
    expect(loaded?.scenario, '日常生活');
    expect(loaded?.messages, hasLength(2));
    expect(loaded?.messages.last.reply?.translation, '先稍微休息一下。');

    await store.clear();
    expect(await store.load(), isNull);
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
        analysis: const LanguageAnalysis(
          detectedLanguage: 'English',
          chinese: '我晚點回覆。',
          english: 'I will reply later.',
          tagalog: 'Babalikan kita mamaya.',
          tone: '自然。',
          learningPoints: [
            LearningPoint(
              title: 'mamaya',
              explanation: '稍後。',
            ),
          ],
        ),
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

  testWidgets('SavedScreen uses gilded card icon without text label',
      (tester) async {
    final item = LearningItem(
      id: 'gilded',
      text: 'I will reply later.',
      createdAt: DateTime(2026, 9, 27),
      analysis: const LanguageAnalysis(
        detectedLanguage: 'English',
        chinese: '我晚點回覆。',
        english: 'I will reply later.',
        tagalog: 'Babalikan kita mamaya.',
        tone: '自然。',
        learningPoints: [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedScreen(
            items: [item],
            isLoading: false,
            onDelete: (_) async {},
            onCategoryChanged: (_, __) async {},
          ),
        ),
      ),
    );

    expect(find.byType(GildedCardIcon), findsOneWidget);
    expect(find.text('完整學習卡'), findsNothing);
  });

  testWidgets('LearningCardScreen shows gilded header and copy actions',
      (tester) async {
    final item = LearningItem(
      id: 'card',
      text: 'I will reply later.',
      createdAt: DateTime(2026, 9, 27),
      analysis: const LanguageAnalysis(
        detectedLanguage: 'English',
        chinese: '我晚點回覆。',
        english: 'I will reply later.',
        tagalog: 'Babalikan kita mamaya.',
        tone: '自然。',
        learningPoints: [
          LearningPoint(
            title: 'mamaya',
            explanation: '稍後。',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LearningCardScreen(item: item),
      ),
    );

    expect(find.byType(GildedCardIcon), findsNWidgets(2));
    expect(find.text('完整學習卡'), findsNothing);
    expect(find.text('快速操作'), findsOneWidget);
    expect(find.text('複製中文'), findsOneWidget);
    expect(find.text('複製 English'), findsOneWidget);
    expect(find.text('複製 Tagalog'), findsOneWidget);
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
    expect(item.analysis, isNull);
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
        analysis: const LanguageAnalysis(
          detectedLanguage: 'English',
          chinese: '我晚點回覆。',
          english: 'I will reply later.',
          tagalog: 'Babalikan kita mamaya.',
          tone: '自然。',
          learningPoints: [
            LearningPoint(
              title: 'mamaya',
              explanation: '稍後。',
            ),
          ],
        ),
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
    expect(restored.first.analysis?.chinese, '我晚點回覆。');
    expect(restored.first.analysis?.tagalog, 'Babalikan kita mamaya.');
    expect(restored.first.analysis?.learningPoints.first.title, 'mamaya');
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
