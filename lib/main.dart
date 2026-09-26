import 'package:flutter/material.dart';

import 'models/language_analysis.dart';
import 'models/learning_item.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/backup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/review_screen.dart';
import 'screens/saved_screen.dart';
import 'services/language_analysis_service.dart';
import 'services/learning_store.dart';

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

  int _index = 0;
  bool _isLoadingSavedItems = true;
  List<LearningItem> _savedItems = const [];

  @override
  void initState() {
    super.initState();
    _loadSavedItems();
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
    final pages = [
      HomeScreen(
        items: _savedItems,
        isLoading: _isLoadingSavedItems,
        onStartReview: _startReview,
      ),
      LearnScreen(
        onAnalyze: _analysisService.analyze,
        onSave: _saveLearningItem,
        onSaved: _openSavedItems,
      ),
      const AiChatScreen(),
      SavedScreen(
        items: _savedItems,
        isLoading: _isLoadingSavedItems,
        onDelete: _deleteLearningItem,
        onCategoryChanged: _updateLearningItemCategory,
      ),
      ProfileScreen(
        items: _savedItems,
        isLoading: _isLoadingSavedItems,
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
