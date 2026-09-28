import 'package:flutter/material.dart';

import '../models/daily_training.dart';
import '../models/training_telemetry.dart';

typedef DailyReviewRecorder = Future<void> Function(
  String learningItemId,
  bool remembered,
);
typedef DailyTrainingCompletion = Future<void> Function(
  DailyTrainingSummary summary,
);
typedef DailyTaskResultRecorder = Future<void> Function(
  DailyTrainingTask task,
  bool correct,
);
typedef DailyTelemetryRecorder = Future<void> Function(
  TrainingTelemetry telemetry,
);

class DailyTrainingScreen extends StatefulWidget {
  final DailyTrainingPlan plan;
  final DailyReviewRecorder onReviewResult;
  final DailyTrainingCompletion onCompleted;
  final DailyTaskResultRecorder? onTaskResult;
  final DailyTelemetryRecorder? onTelemetry;
  final String title;

  const DailyTrainingScreen({
    super.key,
    required this.plan,
    required this.onReviewResult,
    required this.onCompleted,
    this.onTaskResult,
    this.onTelemetry,
    this.title = '今日訓練',
  });

  @override
  State<DailyTrainingScreen> createState() => _DailyTrainingScreenState();
}

class _DailyTrainingScreenState extends State<DailyTrainingScreen> {
  late List<DailyTrainingTask> _tasks;
  int _index = 0;
  int _correct = 0;
  int? _selectedChoice;
  bool _revealed = false;
  bool _finished = false;
  bool _saving = false;
  int _consecutiveWrong = 0;
  String? _adaptiveNotice;
  String? _hintText;
  bool _usedHint = false;
  late DateTime _taskStartedAt;
  final Map<String, int> _correctByType = <String, int>{};

  @override
  void initState() {
    super.initState();
    _tasks = [...widget.plan.tasks];
    _taskStartedAt = DateTime.now();
  }

  DailyTrainingTask get _task => _tasks[_index];

  Future<void> _recordTelemetry(
    DailyTrainingTask task,
    bool correct,
  ) async {
    final now = DateTime.now();
    final telemetry = TrainingTelemetry(
      id: now.microsecondsSinceEpoch.toString(),
      taskId: task.id,
      type: task.type,
      correct: correct,
      responseMs: now.difference(_taskStartedAt).inMilliseconds.clamp(
            0,
            120000,
          ),
      usedHint: _usedHint,
      recordedAt: now,
    );
    await widget.onTelemetry?.call(telemetry);
  }

  void _showHint() {
    final task = _task;
    if (_usedHint) return;
    final explanation = task.explanation.trim();
    final answer = task.answer.trim();
    final hint = explanation.isNotEmpty
        ? explanation
        : answer.isEmpty
            ? '先想想這題屬於「${_typeLabel(task.type)}」的哪一種規則。'
            : '答案開頭：${answer.substring(0, 1)}…';
    setState(() {
      _usedHint = true;
      _hintText = hint;
    });
  }

  Future<void> _choose(int choice) async {
    if (_selectedChoice != null || _saving) return;

    final task = _task;
    final isCorrect = choice == task.correctIndex;
    setState(() {
      _selectedChoice = choice;
      if (isCorrect) {
        _correct++;
        _correctByType[task.type] = (_correctByType[task.type] ?? 0) + 1;
      }
    });

    final learningItemId = task.learningItemId;
    if (learningItemId != null) {
      await widget.onReviewResult(learningItemId, isCorrect);
    }
    await widget.onTaskResult?.call(task, isCorrect);
    await _recordTelemetry(task, isCorrect);
    _adaptAfterResult(task, isCorrect);
  }

  void _adaptAfterResult(DailyTrainingTask task, bool correct) {
    if (correct) {
      _consecutiveWrong = 0;
      if (_adaptiveNotice != null && mounted) {
        setState(() => _adaptiveNotice = null);
      }
      return;
    }

    _consecutiveWrong++;
    if (_consecutiveWrong < 2 || _index >= _tasks.length - 1) return;

    final remaining = _tasks.sublist(_index + 1);
    final sameType =
        remaining.where((item) => item.type == task.type).toList();
    final otherType =
        remaining.where((item) => item.type != task.type).toList();
    if (sameType.isEmpty) {
      _consecutiveWrong = 0;
      return;
    }

    setState(() {
      _tasks = [
        ..._tasks.take(_index + 1),
        ...sameType,
        ...otherType,
      ];
      _adaptiveNotice =
          'Shili 偵測到連續失誤，已把「${_typeLabel(task.type)}」同類題提前補強。';
    });
    _consecutiveWrong = 0;
  }

  Future<void> _rateSelf(bool remembered) async {
    if (_saving) return;

    setState(() => _saving = true);
    final task = _task;

    if (remembered) {
      _correct++;
      _correctByType[task.type] = (_correctByType[task.type] ?? 0) + 1;
    }

    final learningItemId = task.learningItemId;
    if (learningItemId != null) {
      await widget.onReviewResult(learningItemId, remembered);
    }
    await widget.onTaskResult?.call(task, remembered);
    await _recordTelemetry(task, remembered);
    _adaptAfterResult(task, remembered);

    if (!mounted) return;
    setState(() => _saving = false);
    await _advance();
  }

  Future<void> _advance() async {
    if (_index < _tasks.length - 1) {
      setState(() {
        _index++;
        _selectedChoice = null;
        _revealed = false;
        _usedHint = false;
        _hintText = null;
        _taskStartedAt = DateTime.now();
      });
      return;
    }

    final summary = DailyTrainingSummary(
      dateKey: DailyTrainingSummary.keyFor(DateTime.now()),
      totalTasks: _tasks.length,
      correctTasks: _correct,
      completedAt: DateTime.now(),
      typeTotals: {
        for (final type in const [
          'vocabulary',
          'grammar',
          'weakness',
          'review',
        ])
          if (_totalFor(type) > 0) type: _totalFor(type),
      },
      typeCorrect: {
        for (final type in const [
          'vocabulary',
          'grammar',
          'weakness',
          'review',
        ])
          if (_correctFor(type) > 0) type: _correctFor(type),
      },
    );

    await widget.onCompleted(summary);
    if (!mounted) return;
    setState(() => _finished = true);
  }

  int _totalFor(String type) =>
      _tasks.where((task) => task.type == type).length;

  int _correctFor(String type) => _correctByType[type] ?? 0;

  String _typeLabel(String type) {
    return switch (type) {
      'vocabulary' => '單字',
      'grammar' => '文法',
      'weakness' => '弱點',
      'review' => 'SRS',
      _ => '練習',
    };
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'vocabulary' => Icons.menu_book_outlined,
      'grammar' => Icons.extension_outlined,
      'weakness' => Icons.track_changes_outlined,
      'review' => Icons.history_rounded,
      _ => Icons.school_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            children: [
              const Icon(Icons.celebration_rounded, size: 56),
              const SizedBox(height: 16),
              Text(
                '今日訓練完成 🎉',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_correct / ${_tasks.length} 題完成',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      for (final type in const [
                        'vocabulary',
                        'grammar',
                        'weakness',
                        'review',
                      ])
                        if (_totalFor(type) > 0)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(_typeIcon(type)),
                            title: Text(_typeLabel(type)),
                            trailing: Text(
                              '${_correctFor(type)} / ${_totalFor(type)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey('finish-daily-training'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('完成'),
              ),
            ],
          ),
        ),
      );
    }

    final task = _task;
    final answered = _selectedChoice != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_index + 1) / _tasks.length,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_index + 1} / ${_tasks.length}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_adaptiveNotice != null)
                Container(
                  key: const ValueKey('adaptive-training-notice'),
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _adaptiveNotice!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    Row(
                      children: [
                        Icon(_typeIcon(task.type), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          task.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.isMultipleChoice
                                  ? task.type == 'vocabulary'
                                      ? '選出正確的中文意思'
                                      : '選出最適合的答案'
                                  : task.type == 'weakness'
                                      ? '你會怎麼說得更自然？'
                                      : '先想一下它的意思',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: const Color(0xFF756B82),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              task.prompt,
                              style:
                                  Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                key: const ValueKey('daily-hint-button'),
                                onPressed:
                                    _usedHint || answered ? null : _showHint,
                                icon: const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text('給我提示'),
                              ),
                            ),
                            if (_hintText != null)
                              Container(
                                key: const ValueKey('daily-hint-box'),
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(_hintText!),
                              ),
                            if (task.isMultipleChoice) ...[
                              const SizedBox(height: 18),
                              for (var optionIndex = 0;
                                  optionIndex < task.options.length;
                                  optionIndex++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      key: ValueKey(
                                        'daily-choice-$optionIndex',
                                      ),
                                      onPressed: answered
                                          ? null
                                          : () => _choose(optionIndex),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Text(task.options[optionIndex]),
                                      ),
                                    ),
                                  ),
                                ),
                              if (answered) ...[
                                const SizedBox(height: 8),
                                _AnswerBox(
                                  correct:
                                      _selectedChoice == task.correctIndex,
                                  answer: task.answer,
                                  explanation: task.explanation,
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    key: const ValueKey('daily-next-task'),
                                    onPressed: _advance,
                                    child: Text(
                                      _index == _tasks.length - 1
                                          ? '查看結果'
                                          : '下一題',
                                    ),
                                  ),
                                ),
                              ],
                            ] else ...[
                              const SizedBox(height: 18),
                              if (!_revealed)
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonal(
                                    key: const ValueKey('reveal-daily-answer'),
                                    onPressed: () =>
                                        setState(() => _revealed = true),
                                    child: const Text('顯示答案'),
                                  ),
                                )
                              else ...[
                                _AnswerBox(
                                  correct: true,
                                  answer: task.answer,
                                  explanation: task.explanation,
                                  neutral: true,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        key: const ValueKey(
                                          'daily-needs-practice',
                                        ),
                                        onPressed: _saving
                                            ? null
                                            : () => _rateSelf(false),
                                        child: const Text('需要再練'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        key: const ValueKey(
                                          'daily-remembered',
                                        ),
                                        onPressed: _saving
                                            ? null
                                            : () => _rateSelf(true),
                                        child: const Text('會了'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerBox extends StatelessWidget {
  final bool correct;
  final bool neutral;
  final String answer;
  final String explanation;

  const _AnswerBox({
    required this.correct,
    required this.answer,
    required this.explanation,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final headline = neutral
        ? '答案'
        : correct
            ? '✅ 答對了'
            : '💡 再記一下';

    return Container(
      key: const ValueKey('daily-answer-feedback'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(answer),
          if (explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              explanation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF756B82),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
