import 'package:flutter/material.dart';

import 'models/ai_coach_reply.dart';
import 'models/daily_training.dart';
import 'models/language_analysis.dart';
import 'models/learning_item.dart';
import 'models/mistake_record.dart';
import 'models/weakness_record.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/backup_screen.dart';
import 'screens/daily_training_screen.dart';
import 'screens/home_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/review_screen.dart';
import 'screens/saved_screen.dart';
import 'services/ai_chat_service.dart';
import 'services/ai_chat_store.dart';
import 'services/daily_training_plan_builder.dart';
import 'services/daily_training_store.dart';
import 'services/language_analysis_service.dart';
import 'services/learning_store.dart';
import 'services/mistake_store.dart';
import 'services/weakness_classifier.dart';
import 'services/weakness_store.dart';

void main() {
  runApp(const LinguaMateApp());
}

class LinguaMateApp extends StatelessWidget {
  const LinguaMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinguaMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _learningStore = LearningStore();
  final _analysisService = LanguageAnalysisService();
  final _aiChatService = AiChatService();
  final _aiChatStore = const AiChatStore();
  final _weaknessStore = const WeaknessStore();
  final _dailyTrainingStore = const DailyTrainingStore();
  final _mistakeStore = const MistakeStore();

  int _index = 0;
  bool _isLoadingSavedItems = true;
  bool _isLoadingWeaknesses = true;
  List<LearningItem> _savedItems = const [];
  List<WeaknessRecord> _weaknesses = const [];
  List<AiCoachReply> _coachReplies = const [];
  List<MistakeRecord> _mistakes = const [];
  DailyTrainingSummary? _dailyTrainingSummary;

  @override
  void initState() {
    super.initState();
    _loadSavedItems();
    _loadWeaknesses();
    _loadTrainingContext();
    _loadMistakes();
  }

  Future<void> _loadSavedItems() async {
    try {
      final items = await _learningStore.loadItems();
      if (!mounted) return;

      setState(() {
        _savedItems = items;
        _isLoadingSavedItems = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _savedItems = const [];
        _isLoadingSavedItems = false;
      });
    }
  }

  Future<void> _loadWeaknesses() async {
    try {
      final records = await _weaknessStore.load();
      if (!mounted) return;

      setState(() {
        _weaknesses = records;
        _isLoadingWeaknesses = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _weaknesses = const [];
        _isLoadingWeaknesses = false;
      });
    }
  }

  Future<void> _loadMistakes() async {
    final records = await _mistakeStore.load();
    if (!mounted) return;
    setState(() => _mistakes = records);
  }

  Future<void> _loadTrainingContext() async {
    final chatState = await _aiChatStore.load();
    final summary = await _dailyTrainingStore.load();
    if (!mounted) return;

    final replies = chatState?.messages
            .map((message) => message.reply)
            .whereType<AiCoachReply>()
            .toList(growable: false) ??
        const <AiCoachReply>[];

    setState(() {
      _coachReplies = replies;
      _dailyTrainingSummary = summary;
    });
  }

  void _captureLearningPack(AiCoachReply reply) {
    if (!mounted) return;

    final updated = [..._coachReplies, reply];
    setState(() {
      _coachReplies = updated.length <= 20
          ? updated
          : updated.sublist(updated.length - 20);
    });
  }

  DailyTrainingPlan _buildDailyTrainingPlan() {
    return DailyTrainingPlanBuilder.build(
      learningItems: _savedItems,
      weaknesses: _weaknesses,
      coachReplies: _coachReplies,
      mistakes: _mistakes,
    );
  }

  Future<void> _recordTrainingResult(
    DailyTrainingTask task,
    bool correct,
  ) async {
    final records = await _mistakeStore.recordResult(
      task: task,
      correct: correct,
    );
    if (!mounted) return;
    setState(() => _mistakes = records);
  }

  Future<void> _startMistakeTraining() async {
    final plan = DailyTrainingPlanBuilder.buildMistakeOnly(_mistakes);
    if (plan.tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目前沒有需要再加強的錯題 🎉')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DailyTrainingScreen(
          title: '錯題加強',
          plan: plan,
          onReviewResult: _recordReviewResult,
          onTaskResult: _recordTrainingResult,
          onCompleted: (_) async {},
        ),
      ),
    );
  }

  Future<void> _completeDailyTraining(
    DailyTrainingSummary summary,
  ) async {
    await _dailyTrainingStore.save(summary);
    if (!mounted) return;
    setState(() => _dailyTrainingSummary = summary);
  }

  Future<void> _startDailyTraining() async {
    final plan = _buildDailyTrainingPlan();

    if (plan.tasks.isEmpty) {
      _openPage(2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('先和 Shili 聊幾句，我就能幫你建立個人化每日訓練 ✨'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DailyTrainingScreen(
          plan: plan,
          onReviewResult: _recordReviewResult,
          onTaskResult: _recordTrainingResult,
          onCompleted: _completeDailyTraining,
        ),
      ),
    );
  }

  Future<bool> _saveLearningItem(
    String text,
    LanguageAnalysis analysis,
  ) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return false;

    final alreadySaved = _savedItems.any(
      (item) => item.text.toLowerCase() == normalizedText.toLowerCase(),
    );
    if (alreadySaved) return false;

    final updatedItems = [
      LearningItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: normalizedText,
        createdAt: DateTime.now(),
        analysis: analysis,
      ),
      ..._savedItems,
    ];

    await _learningStore.saveItems(updatedItems);
    if (!mounted) return true;

    setState(() {
      _savedItems = updatedItems;
    });
    return true;
  }

  Future<bool> _saveChatLearningItem(String text) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return false;

    final alreadySaved = _savedItems.any(
      (item) => item.text.toLowerCase() == normalizedText.toLowerCase(),
    );
    if (alreadySaved) return false;

    final analysis = await _analysisService.analyze(normalizedText);
    return _saveLearningItem(normalizedText, analysis);
  }

  Future<void> _recordChatWeakness(
    String userText,
    AiCoachReply reply,
  ) async {
    final category = WeaknessClassifier.classify(reply);
    if (category == null) return;

    final records = await _weaknessStore.record(
      category: category,
      example: userText,
      correction: reply.correction,
      explanation: reply.explanation,
    );
    if (!mounted) return;

    setState(() {
      _weaknesses = records;
      _isLoadingWeaknesses = false;
    });
  }

  Future<void> _deleteLearningItem(String id) async {
    final updatedItems =
        _savedItems.where((item) => item.id != id).toList(growable: false);

    await _learningStore.saveItems(updatedItems);
    if (!mounted) return;

    setState(() {
      _savedItems = updatedItems;
    });
  }

  Future<void> _updateLearningItemCategory(
    String id,
    String category,
  ) async {
    final updatedItems = _savedItems
        .map(
          (item) => item.id == id
              ? item.copyWith(category: category)
              : item,
        )
        .toList(growable: false);

    await _learningStore.saveItems(updatedItems);
    if (!mounted) return;

    setState(() {
      _savedItems = updatedItems;
    });
  }

  Future<void> _restoreLearningItems(List<LearningItem> items) async {
    await _learningStore.saveItems(items);
    if (!mounted) return;

    setState(() {
      _savedItems = items;
    });
  }

  Future<void> _openBackup() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BackupScreen(
          items: _savedItems,
          onRestore: _restoreLearningItems,
        ),
      ),
    );
  }

  Future<void> _recordReviewResult(
    String id,
    bool remembered,
  ) async {
    final now = DateTime.now();
    final updatedItems = _savedItems
        .map(
          (item) => item.id == id
              ? item.reviewed(
                  remembered: remembered,
                  now: now,
                )
              : item,
        )
        .toList(growable: false);

    await _learningStore.saveItems(updatedItems);
    if (!mounted) return;

    setState(() {
      _savedItems = updatedItems;
    });
  }

  void _openPage(int index) {
    if (!mounted) return;
    setState(() => _index = index);
  }

  void _openSavedItems() => _openPage(3);

  Future<void> _startReview() async {
    if (_isLoadingSavedItems) return;

    if (_savedItems.isEmpty) {
      _openPage(1);
      return;
    }

    final now = DateTime.now();
    final dueItems = _savedItems
        .where((item) => item.isDue(now))
        .take(10)
        .toList(growable: false);

    if (dueItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('今天沒有到期的句子，複習任務完成 🎉'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReviewScreen(
          items: dueItems,
          onReviewResult: _recordReviewResult,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dailyPlan = _buildDailyTrainingPlan();
    final dailyCompleted =
        _dailyTrainingSummary?.isForDate(DateTime.now()) == true;

    final pages = [
      HomeScreen(
        items: _savedItems,
        isLoading: _isLoadingSavedItems,
        dailyTrainingTaskCount: dailyPlan.totalTasks,
        dailyTrainingEstimatedMinutes: dailyPlan.estimatedMinutes,
        dailyTrainingCompleted: dailyCompleted,
        onStartDailyTraining: _startDailyTraining,
        onStartReview: _startReview,
      ),
      LearnScreen(
        onAnalyze: _analysisService.analyze,
        onSave: _saveLearningItem,
        onSaved: _openSavedItems,
      ),
      AiChatScreen(
        onSend: _aiChatService.send,
        onSaveLearning: _saveChatLearningItem,
        onWeaknessDetected: _recordChatWeakness,
        onLearningPackUpdated: _captureLearningPack,
      ),
      SavedScreen(
        items: _savedItems,
        isLoading: _isLoadingSavedItems,
        onDelete: _deleteLearningItem,
        onCategoryChanged: _updateLearningItemCategory,
      ),
      ProfileScreen(
        items: _savedItems,
        isLoading: _isLoadingSavedItems,
        weaknesses: _weaknesses,
        isLoadingWeaknesses: _isLoadingWeaknesses,
        mistakes: _mistakes,
        onPracticeMistakes: _startMistakeTraining,
        onOpenBackup: _openBackup,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _openPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首頁',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '學習',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: '收藏',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
