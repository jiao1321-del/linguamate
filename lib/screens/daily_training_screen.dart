import 'package:flutter/material.dart';

import '../models/daily_training.dart';

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

class DailyTrainingScreen extends StatefulWidget {
  final DailyTrainingPlan plan;
  final DailyReviewRecorder onReviewResult;
  final DailyTrainingCompletion onCompleted;
  final DailyTaskResultRecorder? onTaskResult;
  final String title;

  const DailyTrainingScreen({
    super.key,
    required this.plan,
    required this.onReviewResult,
    required this.onCompleted,
    this.onTaskResult,
    this.title = '今日訓練',
  });

  @override
  State<DailyTrainingScreen> createState() => _DailyTrainingScreenState();
}

class _DailyTrainingScreenState extends State<DailyTrainingScreen> {
  int _index = 0;
  int _correct = 0;
  int? _selectedChoice;
  bool _revealed = false;
  bool _finished = false;
  bool _saving = false;
  final Map<String, int> _correctByType = <String, int>{};

  DailyTrainingTask get _task => widget.plan.tasks[_index];

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

    if (!mounted) return;
    setState(() => _saving = false);
    await _advance();
  }

  Future<void> _advance() async {
    if (_index < widget.plan.tasks.length - 1) {
      setState(() {
        _index++;
        _selectedChoice = null;
        _revealed = false;
      });
      return;
    }

    final summary = DailyTrainingSummary(
      dateKey: DailyTrainingSummary.keyFor(DateTime.now()),
      totalTasks: widget.plan.totalTasks,
      correctTasks: _correct,
      completedAt: DateTime.now(),
    );

    await widget.onCompleted(summary);
    if (!mounted) return;
    setState(() => _finished = true);
  }

  int _totalFor(String type) => widget.plan.countType(type);

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
                '$_correct / ${widget.plan.totalTasks} 題完成',
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
                      value: (_index + 1) / widget.plan.totalTasks,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_index + 1} / ${widget.plan.totalTasks}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
                                      _index == widget.plan.totalTasks - 1
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
