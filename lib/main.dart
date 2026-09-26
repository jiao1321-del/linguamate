import 'package:flutter/material.dart';

import 'models/learning_item.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/saved_screen.dart';
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

  Future<bool> _saveLearningItem(String text) async {
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

  void _openSavedItems() {
    if (!mounted) return;
    setState(() => _index = 3);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      LearnScreen(
        onSave: _saveLearningItem,
        onSaved: _openSavedItems,
      ),
      const AiChatScreen(),
      SavedScreen(
        items: _savedItems,
        isLoading: _isLoadingSavedItems,
        onDelete: _deleteLearningItem,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
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
