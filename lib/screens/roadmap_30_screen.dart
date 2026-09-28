import 'package:flutter/material.dart';

import '../models/roadmap_30.dart';
import '../services/roadmap_30_generator.dart';

class Roadmap30Screen extends StatefulWidget {
  final String initialGoal;
  final Set<String> initialCompleted;
  final String priority;
  final String weakness;
  final Future<void> Function(String goal) onGoalChanged;
  final Future<Set<String>> Function(String goal, int day) onComplete;
  final ValueChanged<String>? onAction;

  const Roadmap30Screen({
    super.key,
    required this.initialGoal,
    required this.initialCompleted,
    required this.priority,
    required this.weakness,
    required this.onGoalChanged,
    required this.onComplete,
    this.onAction,
  });

  @override
  State<Roadmap30Screen> createState() => _Roadmap30ScreenState();
}

class _Roadmap30ScreenState extends State<Roadmap30Screen> {
  late String _goal;
  late Set<String> _completed;

  @override
  void initState() {
    super.initState();
    _goal = Roadmap30Generator.goals.contains(widget.initialGoal)
        ? widget.initialGoal
        : Roadmap30Generator.goals.first;
    _completed = {...widget.initialCompleted};
  }

  Roadmap30Plan get _plan => Roadmap30Generator.generate(
        goal: _goal,
        priority: widget.priority,
        weakness: widget.weakness,
      );

  bool _done(int day) => _completed.contains('$_goal::$day');

  bool _unlocked(int day) {
    if (day == 1) return true;
    return _done(day - 1);
  }

  Future<void> _changeGoal(String goal) async {
    await widget.onGoalChanged(goal);
    if (!mounted) return;
    setState(() => _goal = goal);
  }

  Future<void> _completeDay(int day) async {
    final updated = await widget.onComplete(_goal, day);
    if (!mounted) return;
    setState(() => _completed = {...updated});
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final completedForGoal =
        plan.days.where((item) => _done(item.day)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('AI 課程 3.0')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Card(
            key: const ValueKey('v143-roadmap-30'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'V1.43 · 30 天長期學習路線',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _goal,
                    decoration: const InputDecoration(labelText: '學習目標'),
                    items: [
                      for (final goal in Roadmap30Generator.goals)
                        DropdownMenuItem(
                          value: goal,
                          child: Text(goal),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) _changeGoal(value);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(plan.summary),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: completedForGoal / 30,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  const SizedBox(height: 5),
                  Text('$completedForGoal / 30 天完成'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var week = 1; week <= 5; week++) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
              child: Text(
                'Week $week',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            for (final day in plan.days.where((item) => item.week == week))
              Card(
                key: ValueKey('roadmap-day-${day.day}'),
                child: ListTile(
                  leading: CircleAvatar(
                    child: _done(day.day)
                        ? const Icon(Icons.check_rounded)
                        : Text('${day.day}'),
                  ),
                  title: Text(
                    day.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${day.focus}${day.checkpoint ? ' · 每週評估' : ''}',
                  ),
                  trailing: IconButton(
                    onPressed: _unlocked(day.day)
                        ? () {
                            widget.onAction?.call(day.action);
                            _completeDay(day.day);
                          }
                        : null,
                    icon: Icon(
                      _unlocked(day.day)
                          ? Icons.play_arrow_rounded
                          : Icons.lock_outline_rounded,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
