import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'models/adaptive_learning.dart';
import 'models/ai_chat_state.dart';
import 'models/ai_coach_reply.dart';
import 'models/cloud_sync_status.dart';
import 'models/gamification.dart';
import 'models/intelligence_core.dart';
import 'models/learner_memory_profile.dart';
import 'models/learning_insights.dart';
import 'models/daily_training.dart';
import 'models/language_analysis.dart';
import 'models/learning_item.dart';
import 'models/learning_ability.dart';
import 'models/learning_path.dart';
import 'models/learning_progress.dart';
import 'models/mistake_record.dart';
import 'models/roleplay_campaign.dart';
import 'models/speaking_attempt.dart';
import 'models/training_telemetry.dart';
import 'models/weakness_record.dart';
import 'screens/adaptive_learning_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/backup_screen.dart';
import 'screens/cloud_sync_screen.dart';
import 'screens/course_plan_screen.dart';
import 'screens/daily_training_screen.dart';
import 'screens/gamification_screen.dart';
import 'screens/growth_center_screen.dart';
import 'screens/intelligence_hub_screen.dart';
import 'screens/learner_memory_screen.dart';
import 'screens/learning_insights_screen.dart';
import 'screens/live_voice_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/progress_center_screen.dart';
import 'screens/review_screen.dart';
import 'screens/roadmap_30_screen.dart';
import 'screens/roleplay_campaign_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/speaking_progress_screen.dart';
import 'services/adaptive_course_generator.dart';
import 'services/adaptive_learning_engine.dart';
import 'services/ai_chat_service.dart';
import 'services/ai_chat_store.dart';
import 'services/cloud_payload_merger.dart';
import 'services/cloud_sync_service.dart';
import 'services/course_progress_store.dart';
import 'services/daily_training_plan_builder.dart';
import 'services/daily_training_store.dart';
import 'services/daily_goal_store.dart';
import 'services/gamification_engine.dart';
import 'services/intelligence_core_engine.dart';
import 'services/language_analysis_service.dart';
import 'services/learning_ability_analyzer.dart';
import 'services/learning_ability_store.dart';
import 'services/learner_memory_engine.dart';
import 'services/learner_memory_store.dart';
import 'services/learning_insights_engine.dart';
import 'services/learning_path_planner.dart';
import 'services/learning_progress_store.dart';
import 'services/learning_store.dart';
import 'services/mistake_store.dart';
import 'services/onboarding_store.dart';
import 'services/roadmap_30_store.dart';
import 'services/roleplay_campaign_store.dart';
import 'services/speaking_history_store.dart';
import 'services/training_telemetry_store.dart';
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
  final _dailyGoalStore = const DailyGoalStore();
  final _mistakeStore = const MistakeStore();
  final _learningAbilityStore = const LearningAbilityStore();
  final _learningProgressStore = const LearningProgressStore();
  final _speakingHistoryStore = const SpeakingHistoryStore();
  final _courseProgressStore = const CourseProgressStore();
  final _cloudSyncService = const CloudSyncService();
  final _learnerMemoryStore = const LearnerMemoryStore();
  final _telemetryStore = const TrainingTelemetryStore();
  final _campaignStore = const RoleplayCampaignStore();
  final _roadmapStore = const Roadmap30Store();
  final _onboardingStore = const OnboardingStore();

  int _index = 0;
  bool _isLoadingSavedItems = true;
  bool _isLoadingWeaknesses = true;
  List<LearningItem> _savedItems = const [];
  List<WeaknessRecord> _weaknesses = const [];
  List<AiCoachReply> _coachReplies = const [];
  List<MistakeRecord> _mistakes = const [];
  List<LearningAbilityRecord> _abilityRecords = const [];
  List<DailyTrainingSummary> _trainingHistory = const [];
  List<SpeakingAttempt> _speakingHistory = const [];
  List<TrainingTelemetry> _trainingTelemetry = const [];
  LearnerMemoryProfile _learnerMemory = LearnerMemoryProfile.empty();
  Set<String> _completedCourseChapters = <String>{};
  Set<String> _completedCampaignMissions = <String>{};
  Set<String> _completedRoadmapDays = <String>{};
  DailyTrainingSummary? _dailyTrainingSummary;
  int _dailyGoal = DailyGoalStore.defaultGoal;
  String _roadmapGoal = '日常英文';
  String? _pendingMissionId;
  int _dataRevision = 0;
  bool _autoSyncEnabled = true;
  bool _syncInProgress = false;
  DateTime _localUpdatedAt = DateTime.fromMillisecondsSinceEpoch(0);
  CloudSyncStatus _cloudStatus = const CloudSyncStatus.signedOut();
  Timer? _cloudSyncDebounce;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _cloudSyncDebounce?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait<void>([
      _loadSavedItems(),
      _loadWeaknesses(),
      _loadTrainingContext(),
      _loadMistakes(),
      _loadLearningAbility(),
      _loadLearningProgress(),
      _loadDailyGoal(),
      _loadSpeakingHistory(),
      _loadCourseProgress(),
      _loadTelemetry(),
      _loadCampaignProgress(),
      _loadRoadmapProgress(),
      _loadLearnerMemory(),
    ]);
    if (!mounted) return;

    final storedLocalUpdated =
        await _cloudSyncService.loadLocalUpdatedAt();
    final hasLocalData = _savedItems.isNotEmpty ||
        _weaknesses.isNotEmpty ||
        _mistakes.isNotEmpty ||
        _abilityRecords.isNotEmpty ||
        _trainingHistory.isNotEmpty ||
        _speakingHistory.isNotEmpty;
    _localUpdatedAt = storedLocalUpdated ??
        (hasLocalData
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(0));
    if (storedLocalUpdated == null && hasLocalData) {
      await _cloudSyncService.markLocalUpdated(_localUpdatedAt);
    }

    await _refreshLearnerMemory();
    _autoSyncEnabled = await _cloudSyncService.loadAutoSyncEnabled();
    final lastSync = await _cloudSyncService.loadLastSyncedAt();
    final session = await _cloudSyncService.loadSession();
    if (!mounted) return;
    setState(() {
      _cloudStatus = session == null
          ? const CloudSyncStatus.signedOut()
          : CloudSyncStatus(
              phase: CloudSyncPhase.idle,
              lastSyncedAt: lastSync,
              email: session.email,
            );
    });

    if (kIsWeb) {
      unawaited(_showOnboardingIfNeeded());
    }

    if (_autoSyncEnabled && session != null) {
      await _autoSyncNow();
    }
  }

  Future<void> _showOnboardingIfNeeded() async {
    final completed = await _onboardingStore.isCompleted();
    if (!mounted || completed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_openOnboarding());
    });
  }

  String _scenarioForOnboardingGoal(String goal) {
    if (goal == '旅遊英文') return '旅行';
    if (goal == '工作英文' ||
        goal == '面試英文' ||
        goal == '會議／報告英文') {
      return '工作職場';
    }
    return '日常生活';
  }

  Future<void> _finishOnboarding(
    String language,
    String goal,
  ) async {
    final existing = await _aiChatStore.load();
    final scenario = _scenarioForOnboardingGoal(goal);

    await _onboardingStore.complete(
      language: language,
      goal: goal,
    );
    await _roadmapStore.saveGoal(goal);
    await _aiChatStore.save(
      AiChatState(
        targetLanguage: language,
        scenario: scenario,
        messages: existing?.messages ?? const <AiChatMessage>[],
      ),
    );

    if (!mounted) return;
    setState(() {
      _roadmapGoal = goal;
      _index = 2;
      _dataRevision++;
    });
    _markLocalChanged(refreshMemory: false);
  }

  Future<void> _skipOnboarding() async {
    await _onboardingStore.skip();
  }

  Future<void> _openOnboarding() async {
    final existing = await _aiChatStore.load();
    final storedLanguage = await _onboardingStore.loadLanguage();
    final storedGoal = await _onboardingStore.loadGoal();
    if (!mounted) return;

    final initialLanguage =
        existing?.targetLanguage.trim().isNotEmpty == true
            ? existing!.targetLanguage.trim()
            : storedLanguage;
    final initialGoal =
        _roadmapGoal.trim().isNotEmpty ? _roadmapGoal : storedGoal;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => OnboardingScreen(
          initialLanguage: initialLanguage,
          initialGoal: initialGoal,
          onOpenCloud: _openCloudSync,
          onFinish: _finishOnboarding,
          onSkip: _skipOnboarding,
        ),
      ),
    );
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

  Future<void> _loadLearningAbility() async {
    final records = await _learningAbilityStore.load();
    if (!mounted) return;
    setState(() => _abilityRecords = records);
  }

  Future<void> _loadLearningProgress() async {
    final history = await _learningProgressStore.load();
    if (!mounted) return;
    setState(() => _trainingHistory = history);
  }

  Future<void> _loadDailyGoal() async {
    final goal = await _dailyGoalStore.load();
    if (!mounted) return;
    setState(() => _dailyGoal = goal);
  }

  Future<void> _loadSpeakingHistory() async {
    final attempts = await _speakingHistoryStore.load();
    if (!mounted) return;
    setState(() => _speakingHistory = attempts);
  }

  Future<void> _loadCourseProgress() async {
    final completed = await _courseProgressStore.loadCompleted();
    if (!mounted) return;
    setState(() => _completedCourseChapters = completed);
  }


  Future<void> _loadTelemetry() async {
    final items = await _telemetryStore.load();
    if (!mounted) return;
    setState(() => _trainingTelemetry = items);
  }

  Future<void> _loadCampaignProgress() async {
    final completed = await _campaignStore.loadCompleted();
    if (!mounted) return;
    setState(() => _completedCampaignMissions = completed);
  }

  Future<void> _loadRoadmapProgress() async {
    final results = await Future.wait<Object>([
      _roadmapStore.loadGoal(),
      _roadmapStore.loadCompleted(),
    ]);
    if (!mounted) return;
    setState(() {
      _roadmapGoal = results[0] as String;
      _completedRoadmapDays = results[1] as Set<String>;
    });
  }

  Future<void> _loadLearnerMemory() async {
    final profile = await _learnerMemoryStore.load();
    if (!mounted) return;
    setState(() => _learnerMemory = profile);
  }

  Future<void> _refreshLearnerMemory() async {
    final chatState = await _aiChatStore.load();
    final profile = LearnerMemoryEngine.build(
      abilities: _abilityRecords,
      weaknesses: _weaknesses,
      mistakes: _mistakes,
      speaking: _speakingHistory,
      savedItems: _savedItems,
      chatState: chatState,
    );
    await _learnerMemoryStore.save(profile);
    if (!mounted) return;
    setState(() => _learnerMemory = profile);
  }

  void _markLocalChanged({bool refreshMemory = true}) {
    _localUpdatedAt = DateTime.now();
    unawaited(_cloudSyncService.markLocalUpdated(_localUpdatedAt));
    if (refreshMemory) {
      unawaited(_refreshLearnerMemory());
    }
    _scheduleAutoSync();
  }

  void _scheduleAutoSync() {
    if (!_autoSyncEnabled || _syncInProgress) return;
    _cloudSyncDebounce?.cancel();
    _cloudSyncDebounce = Timer(
      const Duration(seconds: 2),
      () => unawaited(_autoSyncNow()),
    );
  }

  Future<void> _setAutoSyncEnabled(bool enabled) async {
    await _cloudSyncService.setAutoSyncEnabled(enabled);
    if (!mounted) return;
    setState(() => _autoSyncEnabled = enabled);
    if (enabled) {
      await _autoSyncNow();
    }
  }

  Future<void> _autoSyncNow() async {
    if (_syncInProgress) return;
    final session = await _cloudSyncService.loadSession();
    if (session == null) {
      if (mounted) {
        setState(() => _cloudStatus = const CloudSyncStatus.signedOut());
      }
      return;
    }

    _syncInProgress = true;
    if (mounted) {
      setState(() {
        _cloudStatus = CloudSyncStatus(
          phase: CloudSyncPhase.syncing,
          lastSyncedAt: _cloudStatus.lastSyncedAt,
          email: session.email,
        );
      });
    }

    try {
      final local = await _exportCloudPayload();
      final cloud = await _cloudSyncService.download(session);
      final merged = CloudPayloadMerger.merge(local, cloud);
      await _importCloudPayload(merged, fromSync: true);
      await _cloudSyncService.upload(session: session, payload: merged);
      final syncedAt = DateTime.now();
      if (!mounted) return;
      setState(() {
        _cloudStatus = CloudSyncStatus(
          phase: CloudSyncPhase.synced,
          lastSyncedAt: syncedAt,
          email: session.email,
        );
      });
    } catch (error) {
      if (!mounted) return;
      final text = error.toString().toLowerCase();
      final offline = text.contains('network') ||
          text.contains('host') ||
          text.contains('socket') ||
          text.contains('connection');
      setState(() {
        _cloudStatus = CloudSyncStatus(
          phase: offline ? CloudSyncPhase.offline : CloudSyncPhase.error,
          lastSyncedAt: _cloudStatus.lastSyncedAt,
          message: error.toString(),
          email: session.email,
        );
      });
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _updateDailyGoal(int goal) async {
    await _dailyGoalStore.save(goal);
    if (!mounted) return;
    setState(() => _dailyGoal = goal);
    _markLocalChanged(refreshMemory: false);
  }

  String _speakingMemoryHint() {
    if (_speakingHistory.isEmpty) return '';
    final recent = _speakingHistory.take(7).toList(growable: false);
    final average =
        (recent.fold<int>(0, (sum, item) => sum + item.score) / recent.length)
            .round();
    final counts = <String, int>{};
    for (final attempt in recent) {
      for (final word in attempt.missingWords) {
        final normalized = word.trim().toLowerCase();
        if (normalized.isEmpty) continue;
        counts[normalized] = (counts[normalized] ?? 0) + 1;
      }
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final missing = ranked.take(3).map((item) => item.key).join('、');
    return missing.isEmpty
        ? '最近口說平均 $average 分'
        : '最近口說平均 $average 分；常漏字：$missing';
  }

  LearningAbilityReport _buildAbilityReport() {
    return LearningAbilityAnalyzer.build(
      tracked: _abilityRecords,
      mistakes: _mistakes,
      weaknesses: _weaknesses,
    );
  }
  LearningProgressReport _buildProgressReport(
    LearningAbilityReport abilityReport,
  ) {
    final history = [..._trainingHistory];
    final latest = _dailyTrainingSummary;
    if (latest != null &&
        !history.any(
          (item) =>
              item.completedAt == latest.completedAt &&
              item.dateKey == latest.dateKey,
        )) {
      history.add(latest);
    }

    return LearningProgressReport(
      history: history,
      abilityReport: abilityReport,
      activeMistakeCount:
          _mistakes.where((item) => item.isActive).length,
    );
  }

  LearningPathPlan _buildLearningPath(
    LearningAbilityReport abilityReport,
    LearningProgressReport progressReport,
  ) {
    return LearningPathPlanner.build(
      abilityReport: abilityReport,
      progressReport: progressReport,
      mistakes: _mistakes,
    );
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
    _markLocalChanged();
  }

  DailyTrainingPlan _buildDailyTrainingPlan() {
    final abilityReport = _buildAbilityReport();
    return AdaptiveLearningEngine.buildDailyPlan(
      learningItems: _savedItems,
      weaknesses: _weaknesses,
      coachReplies: _coachReplies,
      mistakes: _mistakes,
      abilityReport: abilityReport,
    );
  }

  Future<void> _recordTrainingResult(
    DailyTrainingTask task,
    bool correct,
  ) async {
    final mistakes = await _mistakeStore.recordResult(
      task: task,
      correct: correct,
    );
    final abilities = await _learningAbilityStore.recordResult(
      task: task,
      correct: correct,
    );
    if (!mounted) return;

    setState(() {
      _mistakes = mistakes;
      _abilityRecords = abilities;
    });
    _markLocalChanged();
  }

  Future<void> _recordSpeakingResult(
    PronunciationAssessment assessment,
  ) async {
    final task = DailyTrainingTask(
      id: 'speaking-${DateTime.now().millisecondsSinceEpoch}',
      type: 'speaking',
      title: '口說練習',
      prompt: assessment.target,
      answer: assessment.naturalSuggestion,
      explanation:
          '辨識：${assessment.transcript} · 完整度 ${assessment.completeness}% · 流暢度 ${assessment.fluency}%',
    );
    final results = await Future.wait<Object>([
      _learningAbilityStore.recordResult(
        task: task,
        correct: assessment.passed,
      ),
      _speakingHistoryStore.append(assessment),
    ]);
    if (!mounted) return;
    setState(() {
      _abilityRecords =
          results[0] as List<LearningAbilityRecord>;
      _speakingHistory =
          results[1] as List<SpeakingAttempt>;
    });
    _markLocalChanged();
  }

  Future<void> _recordTelemetry(TrainingTelemetry telemetry) async {
    final updated = await _telemetryStore.append(telemetry);
    if (!mounted) return;
    setState(() => _trainingTelemetry = updated);
    _markLocalChanged(refreshMemory: false);
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
          onTelemetry: _recordTelemetry,
          onCompleted: (_) async {},
        ),
      ),
    );
  }

  Future<void> _completeDailyTraining(
    DailyTrainingSummary summary,
  ) async {
    await _dailyTrainingStore.save(summary);
    final history = await _learningProgressStore.append(summary);
    if (!mounted) return;
    setState(() {
      _dailyTrainingSummary = summary;
      _trainingHistory = history;
    });
    _markLocalChanged();
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
          onTelemetry: _recordTelemetry,
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
    _markLocalChanged();
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
    _markLocalChanged();
  }

  Future<void> _deleteLearningItem(String id) async {
    final updatedItems =
        _savedItems.where((item) => item.id != id).toList(growable: false);

    await _learningStore.saveItems(updatedItems);
    if (!mounted) return;

    setState(() {
      _savedItems = updatedItems;
    });
    _markLocalChanged();
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
    _markLocalChanged();
  }

  Future<void> _restoreLearningItems(List<LearningItem> items) async {
    await _learningStore.saveItems(items);
    if (!mounted) return;

    setState(() {
      _savedItems = items;
    });
    _markLocalChanged();
  }

  Future<void> _openProgressCenter() async {
    final abilityReport = _buildAbilityReport();
    final progressReport = _buildProgressReport(abilityReport);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProgressCenterScreen(
          report: progressReport,
        ),
      ),
    );
  }

  Future<void> _openGrowthCenter() async {
    final abilityReport = _buildAbilityReport();
    final progressReport = _buildProgressReport(abilityReport);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GrowthCenterScreen(
          report: progressReport,
          initialDailyGoal: _dailyGoal,
          onDailyGoalChanged: _updateDailyGoal,
        ),
      ),
    );
  }

  Future<void> _openAdaptiveLearning() async {
    final abilityReport = _buildAbilityReport();
    final progressReport = _buildProgressReport(abilityReport);
    final snapshot = AdaptiveLearningEngine.buildSnapshot(
      learningItems: _savedItems,
      abilityReport: abilityReport,
      progressReport: progressReport,
      mistakes: _mistakes,
      weaknesses: _weaknesses,
      dailyGoal: _dailyGoal,
      telemetry: _trainingTelemetry,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AdaptiveLearningScreen(
          snapshot: snapshot,
          onAction: _handleAdaptiveAction,
        ),
      ),
    );
  }

  Future<void> _openSpeakingProgress() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SpeakingProgressScreen(
          attempts: _speakingHistory,
        ),
      ),
    );
  }

  Future<void> _openLearnerMemory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LearnerMemoryScreen(
          profile: _learnerMemory,
        ),
      ),
    );
  }

  Future<void> _openLiveVoice() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LiveVoiceScreen(
          onSend: _aiChatService.send,
          learnerMemory: _learnerMemory.summary,
        ),
      ),
    );
  }

  Future<void> _completeCampaignMission(String missionId) async {
    final completed = await _campaignStore.complete(missionId);
    if (!mounted) return;
    setState(() {
      _completedCampaignMissions = completed;
      if (_pendingMissionId == missionId) {
        _pendingMissionId = null;
      }
    });
    _markLocalChanged(refreshMemory: false);
  }

  void _launchCampaignMission(String missionId) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {
      _pendingMissionId = missionId;
      _index = 2;
      _dataRevision++;
    });
  }

  Future<void> _openRoleplayCampaign() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RoleplayCampaignScreen(
          campaign: RoleplayCampaign.overseasWork,
          completedMissionIds: _completedCampaignMissions,
          onStartMission: _launchCampaignMission,
        ),
      ),
    );
  }

  Future<void> _setRoadmapGoal(String goal) async {
    await _roadmapStore.saveGoal(goal);
    if (!mounted) return;
    setState(() => _roadmapGoal = goal);
    _markLocalChanged(refreshMemory: false);
  }

  Future<Set<String>> _completeRoadmapDay(
    String goal,
    int day,
  ) async {
    final completed = await _roadmapStore.complete(
      goal: goal,
      day: day,
    );
    if (mounted) {
      setState(() => _completedRoadmapDays = completed);
      _markLocalChanged(refreshMemory: false);
    }
    return completed;
  }

  Future<void> _openRoadmap30() async {
    final abilityReport = _buildAbilityReport();
    final priority = abilityReport.priorityLabel ?? '自然表達';
    final weakness = _weaknesses.isEmpty
        ? priority
        : _weaknesses.first.category;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Roadmap30Screen(
          initialGoal: _roadmapGoal,
          initialCompleted: _completedRoadmapDays,
          priority: priority,
          weakness: weakness,
          onGoalChanged: _setRoadmapGoal,
          onComplete: _completeRoadmapDay,
          onAction: _handleAdaptiveAction,
        ),
      ),
    );
  }

  GamificationSnapshot _buildGamification(
    LearningProgressReport progressReport,
  ) {
    return GamificationEngine.build(
      progress: progressReport,
      speaking: _speakingHistory,
      dailyGoal: _dailyGoal,
      courseCompleted: _completedCourseChapters,
      campaignCompleted: _completedCampaignMissions,
      roadmapCompleted: _completedRoadmapDays,
    );
  }

  LearningInsightsSnapshot _buildInsights(
    LearningProgressReport progressReport,
  ) {
    return LearningInsightsEngine.build(
      progress: progressReport,
      abilities: _abilityRecords,
      mistakes: _mistakes,
      speaking: _speakingHistory,
      telemetry: _trainingTelemetry,
    );
  }

  Future<void> _openGamification() async {
    final abilityReport = _buildAbilityReport();
    final progressReport = _buildProgressReport(abilityReport);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GamificationScreen(
          snapshot: _buildGamification(progressReport),
        ),
      ),
    );
  }

  Future<void> _openInsights() async {
    final abilityReport = _buildAbilityReport();
    final progressReport = _buildProgressReport(abilityReport);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LearningInsightsScreen(
          snapshot: _buildInsights(progressReport),
        ),
      ),
    );
  }

  IntelligenceCoreSnapshot _buildIntelligence(
    LearningProgressReport progressReport,
    AdaptiveLearningSnapshot adaptiveSnapshot,
  ) {
    return IntelligenceCoreEngine.build(
      memory: _learnerMemory,
      insights: _buildInsights(progressReport),
      gamification: _buildGamification(progressReport),
      learningItems: _savedItems,
      mistakes: _mistakes,
      adaptiveDifficulty: adaptiveSnapshot.difficulty,
      roadmapCompleted: _completedRoadmapDays,
      campaignCompleted: _completedCampaignMissions,
      courseCompleted: _completedCourseChapters,
    );
  }

  Future<void> _openIntelligenceHub() async {
    final abilityReport = _buildAbilityReport();
    final progressReport = _buildProgressReport(abilityReport);
    final adaptiveSnapshot = AdaptiveLearningEngine.buildSnapshot(
      learningItems: _savedItems,
      abilityReport: abilityReport,
      progressReport: progressReport,
      mistakes: _mistakes,
      weaknesses: _weaknesses,
      dailyGoal: _dailyGoal,
      telemetry: _trainingTelemetry,
    );
    final snapshot = _buildIntelligence(
      progressReport,
      adaptiveSnapshot,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => IntelligenceHubScreen(
          snapshot: snapshot,
          onAction: _handleAdaptiveAction,
          onOpenCloud: _openCloudSync,
          onOpenMemory: _openLearnerMemory,
          onOpenSpeaking: _openSpeakingProgress,
          onOpenLiveVoice: _openLiveVoice,
          onOpenCampaign: _openRoleplayCampaign,
          onOpenRoadmap: _openRoadmap30,
          onOpenGamification: _openGamification,
          onOpenInsights: _openInsights,
        ),
      ),
    );
  }

  Future<Set<String>> _completeCourseChapter(String chapterId) async {
    final completed = await _courseProgressStore.complete(chapterId);
    if (mounted) {
      setState(() => _completedCourseChapters = completed);
      _markLocalChanged(refreshMemory: false);
    }
    return completed;
  }

  Future<void> _openCoursePlan() async {
    final abilityReport = _buildAbilityReport();
    final progressReport = _buildProgressReport(abilityReport);
    final plan = AdaptiveCourseGenerator.generate(
      abilityReport: abilityReport,
      progressReport: progressReport,
      mistakes: _mistakes,
      weaknesses: _weaknesses,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CoursePlanScreen(
          plan: plan,
          initialCompleted: _completedCourseChapters,
          onCompleteChapter: _completeCourseChapter,
          onAction: _handleAdaptiveAction,
        ),
      ),
    );
  }

  List<T> _decodeCloudList<T>(
    dynamic raw,
    T Function(Map<String, dynamic> json) parser,
  ) {
    if (raw is! List) return <T>[];
    final items = <T>[];
    for (final entry in raw.whereType<Map>()) {
      try {
        items.add(parser(Map<String, dynamic>.from(entry)));
      } catch (_) {}
    }
    return items;
  }

  Future<Map<String, dynamic>> _exportCloudPayload() async {
    final chatState = await _aiChatStore.load();
    return {
      'schemaVersion': 146,
      'savedItems': _savedItems.map((item) => item.toJson()).toList(),
      'weaknesses': _weaknesses.map((item) => item.toJson()).toList(),
      'mistakes': _mistakes.map((item) => item.toJson()).toList(),
      'abilities': _abilityRecords.map((item) => item.toJson()).toList(),
      'trainingHistory':
          _trainingHistory.map((item) => item.toJson()).toList(),
      'dailyGoal': _dailyGoal,
      'speakingHistory':
          _speakingHistory.map((item) => item.toJson()).toList(),
      'courseCompleted': _completedCourseChapters.toList(),
      'campaignCompleted': _completedCampaignMissions.toList(),
      'roadmapCompleted': _completedRoadmapDays.toList(),
      'roadmapGoal': _roadmapGoal,
      'trainingTelemetry':
          _trainingTelemetry.map((item) => item.toJson()).toList(),
      'learnerMemory': _learnerMemory.toJson(),
      'chatState': chatState?.toJson(),
      'syncedAt': _localUpdatedAt.toUtc().toIso8601String(),
    };
  }

  Future<void> _importCloudPayload(
    Map<String, dynamic> payload, {
    bool fromSync = false,
  }) async {
    final items = _decodeCloudList<LearningItem>(
      payload['savedItems'],
      LearningItem.fromJson,
    );
    final weaknesses = _decodeCloudList<WeaknessRecord>(
      payload['weaknesses'],
      WeaknessRecord.fromJson,
    );
    final mistakes = _decodeCloudList<MistakeRecord>(
      payload['mistakes'],
      MistakeRecord.fromJson,
    );
    final abilities = _decodeCloudList<LearningAbilityRecord>(
      payload['abilities'],
      LearningAbilityRecord.fromJson,
    );
    final history = _decodeCloudList<DailyTrainingSummary>(
      payload['trainingHistory'],
      DailyTrainingSummary.fromJson,
    );
    final speaking = _decodeCloudList<SpeakingAttempt>(
      payload['speakingHistory'],
      SpeakingAttempt.fromJson,
    );
    final telemetry = _decodeCloudList<TrainingTelemetry>(
      payload['trainingTelemetry'],
      TrainingTelemetry.fromJson,
    );
    final campaignRaw = payload['campaignCompleted'];
    final campaignCompleted = campaignRaw is List
        ? campaignRaw.whereType<String>().toSet()
        : <String>{};
    final roadmapRaw = payload['roadmapCompleted'];
    final roadmapCompleted = roadmapRaw is List
        ? roadmapRaw.whereType<String>().toSet()
        : <String>{};
    final roadmapGoal =
        (payload['roadmapGoal'] as String? ?? '日常英文').trim();
    final rawMemory = payload['learnerMemory'];
    final learnerMemory = rawMemory is Map
        ? LearnerMemoryProfile.fromJson(
            Map<String, dynamic>.from(rawMemory),
          )
        : LearnerMemoryProfile.empty();
    final completedRaw = payload['courseCompleted'];
    final completed = completedRaw is List
        ? completedRaw.whereType<String>().toSet()
        : <String>{};
    final goal = (payload['dailyGoal'] as num?)?.toInt() ??
        DailyGoalStore.defaultGoal;
    final rawChat = payload['chatState'];
    final chatState = rawChat is Map
        ? AiChatState.fromJson(Map<String, dynamic>.from(rawChat))
        : null;

    await _learningStore.saveItems(items);
    await _weaknessStore.replace(weaknesses);
    await _mistakeStore.replace(mistakes);
    await _learningAbilityStore.replace(abilities);
    await _learningProgressStore.replace(history);
    await _dailyGoalStore.save(goal);
    await _speakingHistoryStore.replace(speaking);
    await _courseProgressStore.replace(completed);
    await _telemetryStore.replace(telemetry);
    await _campaignStore.replace(campaignCompleted);
    await _roadmapStore.replace(roadmapCompleted);
    await _roadmapStore.saveGoal(roadmapGoal);
    await _learnerMemoryStore.save(learnerMemory);

    if (chatState == null) {
      await _aiChatStore.clear();
    } else {
      await _aiChatStore.save(chatState);
    }

    if (history.isEmpty) {
      await _dailyTrainingStore.clear();
    } else {
      await _dailyTrainingStore.save(history.first);
    }

    if (!mounted) return;
    final replies = chatState?.messages
            .map((message) => message.reply)
            .whereType<AiCoachReply>()
            .toList(growable: false) ??
        const <AiCoachReply>[];

    setState(() {
      _savedItems = items;
      _weaknesses = weaknesses;
      _mistakes = mistakes;
      _abilityRecords = abilities;
      _trainingHistory = history;
      _dailyTrainingSummary = history.isEmpty ? null : history.first;
      _dailyGoal = DailyGoalStore.supportedGoals.contains(goal)
          ? goal
          : DailyGoalStore.defaultGoal;
      _speakingHistory = speaking;
      _trainingTelemetry = telemetry;
      _completedCourseChapters = completed;
      _completedCampaignMissions = campaignCompleted;
      _completedRoadmapDays = roadmapCompleted;
      _roadmapGoal = roadmapGoal.isEmpty ? '日常英文' : roadmapGoal;
      _learnerMemory = learnerMemory;
      _coachReplies = replies;
      _isLoadingSavedItems = false;
      _isLoadingWeaknesses = false;
      _dataRevision++;
    });
    final syncedAt =
        DateTime.tryParse(payload['syncedAt'] as String? ?? '');
    if (syncedAt != null && syncedAt.isAfter(_localUpdatedAt)) {
      _localUpdatedAt = syncedAt.toLocal();
    }
    if (!fromSync) {
      _markLocalChanged(refreshMemory: false);
    }
  }

  Future<void> _openCloudSync() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CloudSyncScreen(
          service: _cloudSyncService,
          exportLocal: _exportCloudPayload,
          importCloud: _importCloudPayload,
          status: _cloudStatus,
          autoSyncEnabled: _autoSyncEnabled,
          onAutoSyncChanged: _setAutoSyncEnabled,
          onSyncNow: _autoSyncNow,
        ),
      ),
    );
  }

  void _handleAdaptiveAction(String action) {
    switch (action) {
      case 'mistakes':
        Navigator.of(context).popUntil((route) => route.isFirst);
        _startMistakeTraining();
        break;
      case 'speaking':
        Navigator.of(context).popUntil((route) => route.isFirst);
        _openPage(2);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已切到 Shili，點「口說評分」就能開始。'),
          ),
        );
        break;
      case 'roleplay':
        Navigator.of(context).popUntil((route) => route.isFirst);
        _openPage(2);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已切到 Shili，點上方 🎭 選擇情境任務。'),
          ),
        );
        break;
      case 'liveVoice':
        Navigator.of(context).popUntil((route) => route.isFirst);
        _openLiveVoice();
        break;
      case 'roadmap':
        Navigator.of(context).popUntil((route) => route.isFirst);
        _openRoadmap30();
        break;
      case 'campaign':
        Navigator.of(context).popUntil((route) => route.isFirst);
        _openRoleplayCampaign();
        break;
      case 'course':
        Navigator.of(context).popUntil((route) => route.isFirst);
        _openCoursePlan();
        break;
      case 'ai':
        Navigator.of(context).popUntil((route) => route.isFirst);
        _openPage(2);
        break;
      case 'daily':
      default:
        Navigator.of(context).popUntil((route) => route.isFirst);
        _startDailyTraining();
    }
  }

  void _handleLearningPathAction(String action) {
    switch (action) {
      case 'mistakes':
        _startMistakeTraining();
        break;
      case 'ai':
        _openPage(2);
        break;
      case 'roleplay':
        _openPage(2);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已切到 Shili，點上方 🎭 就能選擇情境任務。'),
          ),
        );
        break;
      case 'daily':
      default:
        _startDailyTraining();
    }
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
    final abilityReport = _buildAbilityReport();
    final progressReport = _buildProgressReport(abilityReport);
    final updatedItems = _savedItems.map((item) {
      if (item.id != id) return item;
      return AdaptiveLearningEngine.reviewItem(
        item: item,
        remembered: remembered,
        progressReport: progressReport,
        now: now,
      ).item;
    }).toList(growable: false);

    await _learningStore.saveItems(updatedItems);
    if (!mounted) return;

    setState(() {
      _savedItems = updatedItems;
    });
    _markLocalChanged();
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
    final abilityReport = _buildAbilityReport();
    final progressReport = _buildProgressReport(abilityReport);
    final learningPath = _buildLearningPath(
      abilityReport,
      progressReport,
    );
    final adaptiveSnapshot = AdaptiveLearningEngine.buildSnapshot(
      learningItems: _savedItems,
      abilityReport: abilityReport,
      progressReport: progressReport,
      mistakes: _mistakes,
      weaknesses: _weaknesses,
      dailyGoal: _dailyGoal,
      telemetry: _trainingTelemetry,
    );
    final intelligenceSnapshot = _buildIntelligence(
      progressReport,
      adaptiveSnapshot,
    );
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
        dailyTrainingFocusLabel: abilityReport.priorityLabel,
        learningStreak: progressReport.streakAt(DateTime.now()),
        learningPath: learningPath,
        onLearningPathAction: _handleLearningPathAction,
        onStartDailyTraining: _startDailyTraining,
        onStartReview: _startReview,
      ),
      LearnScreen(
        onAnalyze: _analysisService.analyze,
        onSave: _saveLearningItem,
        onSaved: _openSavedItems,
      ),
      AiChatScreen(
        key: ValueKey('ai-chat-$_dataRevision'),
        onSend: _aiChatService.send,
        onSaveLearning: _saveChatLearningItem,
        onWeaknessDetected: _recordChatWeakness,
        onLearningPackUpdated: _captureLearningPack,
        proactiveCoachMessage: intelligenceSnapshot.coachMessage,
        learnerMemory: [
          _learnerMemory.summary,
          adaptiveSnapshot.memory.summary,
          _speakingMemoryHint(),
        ].where((item) => item.trim().isNotEmpty).join('；'),
        onSpeakingResult: _recordSpeakingResult,
        onStartRecommendedTraining: () => _handleAdaptiveAction(
          intelligenceSnapshot.nextBestAction.action,
        ),
        initialMissionId: _pendingMissionId,
        onMissionCompleted: _completeCampaignMission,
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
        abilityReport: abilityReport,
        onPracticeMistakes: _startMistakeTraining,
        onOpenProgress: _openProgressCenter,
        onOpenGrowth: _openGrowthCenter,
        onOpenAdaptive: _openAdaptiveLearning,
        onOpenIntelligence: _openIntelligenceHub,
        onOpenSpeaking: _openSpeakingProgress,
        onOpenCourse: _openCoursePlan,
        onOpenCloud: _openCloudSync,
        onOpenOnboarding: _openOnboarding,
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
