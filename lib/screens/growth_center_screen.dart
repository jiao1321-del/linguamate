import 'package:flutter/material.dart';

import '../models/learning_growth.dart';
import '../models/learning_progress.dart';
import '../services/daily_goal_store.dart';

class GrowthCenterScreen extends StatefulWidget {
  final LearningProgressReport report;
  final int initialDailyGoal;
  final Future<void> Function(int goal)? onDailyGoalChanged;
  final DateTime? now;

  const GrowthCenterScreen({
    super.key,
    required this.report,
    this.initialDailyGoal = DailyGoalStore.defaultGoal,
    this.onDailyGoalChanged,
    this.now,
  });

  @override
  State<GrowthCenterScreen> createState() => _GrowthCenterScreenState();
}

class _GrowthCenterScreenState extends State<GrowthCenterScreen> {
  late int _dailyGoal;

  @override
  void initState() {
    super.initState();
    _dailyGoal = widget.initialDailyGoal;
  }

  Future<void> _setGoal(int goal) async {
    if (_dailyGoal == goal) return;
    setState(() => _dailyGoal = goal);
    await widget.onDailyGoalChanged?.call(goal);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = LearningGrowthSnapshot.fromReport(
      report: widget.report,
      now: widget.now ?? DateTime.now(),
      dailyGoal: _dailyGoal,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('成長中心'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          Text(
            '把每天的小進步變成看得見的累積 ✨',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          _DailyGoalCard(
            snapshot: snapshot,
            onGoalChanged: _setGoal,
          ),
          const SizedBox(height: 14),
          _LevelCard(snapshot: snapshot),
          const SizedBox(height: 14),
          _BadgeCard(snapshot: snapshot),
          const SizedBox(height: 14),
          _WeeklyInsightCard(snapshot: snapshot),
          const SizedBox(height: 14),
          _LearningCalendarCard(snapshot: snapshot),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  final LearningGrowthSnapshot snapshot;
  final Future<void> Function(int goal) onGoalChanged;

  const _DailyGoalCard({
    required this.snapshot,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('daily-goal-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'V1.20 · 每日目標',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '${snapshot.todayTasks} / ${snapshot.dailyGoal} 題',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: snapshot.dailyGoalProgress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 10),
            Text(
              snapshot.dailyGoalCompleted
                  ? '今天的目標完成了 🎉'
                  : '還差 ${snapshot.dailyGoal - snapshot.todayTasks} 題達成今天的目標。',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final goal in DailyGoalStore.supportedGoals)
                  ChoiceChip(
                    key: ValueKey('daily-goal-$goal'),
                    label: Text('$goal 題'),
                    selected: snapshot.dailyGoal == goal,
                    onSelected: (_) => onGoalChanged(goal),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final LearningGrowthSnapshot snapshot;

  const _LevelCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('growth-level-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'V1.21 · XP 與等級',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  'Lv. ${snapshot.level}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${snapshot.xp} XP · 距離下一級 ${snapshot.xpToNextLevel} XP',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: snapshot.levelProgress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            Text(
              '答對題目、完成訓練與維持連續學習都會累積 XP。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final LearningGrowthSnapshot snapshot;

  const _BadgeCard({required this.snapshot});

  IconData _iconFor(String id) {
    switch (id) {
      case 'streak-3':
      case 'streak-7':
        return Icons.local_fire_department_rounded;
      case 'tasks-50':
      case 'tasks-100':
        return Icons.workspace_premium_outlined;
      case 'accuracy-80':
        return Icons.gps_fixed_rounded;
      case 'clear-mistakes':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('achievement-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.military_tech_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'V1.22 · 成就徽章',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                Text(
                  '${snapshot.unlockedBadgeCount} / ${snapshot.badges.length}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final badge in snapshot.badges)
                      SizedBox(
                        width: width,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: badge.unlocked
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(_iconFor(badge.id)),
                              const SizedBox(height: 8),
                              Text(
                                badge.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                badge.description,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                badge.unlocked ? '已解鎖' : '尚未解鎖',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: badge.unlocked
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyInsightCard extends StatelessWidget {
  final LearningGrowthSnapshot snapshot;

  const _WeeklyInsightCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final best = snapshot.bestSkillLabel ?? '尚待累積資料';
    final focus = snapshot.focusSkillLabel ?? '維持目前節奏';

    return Card(
      key: const ValueKey('weekly-insight-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                const Text(
                  'V1.23 · 近 7 天週報',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: '學習天數',
                    value: '${snapshot.weeklyDays} 天',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: '完成題數',
                    value: '${snapshot.weeklyTasks} 題',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: '答對率',
                    value: '${snapshot.weeklyAccuracy}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              snapshot.weeklyTrendLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('目前表現最好：$best'),
            const SizedBox(height: 4),
            Text('下一個優先：$focus'),
          ],
        ),
      ),
    );
  }
}

class _LearningCalendarCard extends StatelessWidget {
  final LearningGrowthSnapshot snapshot;

  const _LearningCalendarCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('learning-calendar-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                const Text(
                  'V1.24 · 28 天學習日曆',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '有完成訓練的日期會標記題數，讓節奏一眼就看得出來。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.calendar.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                final day = snapshot.calendar[index];
                return Tooltip(
                  message: day.completed
                      ? '${day.date.month}/${day.date.day} · ${day.correct}/${day.tasks} 題答對'
                      : '${day.date.month}/${day.date.day} · 無訓練',
                  child: Container(
                    decoration: BoxDecoration(
                      color: day.completed
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.date.day}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        if (day.completed)
                          Text(
                            '${day.tasks}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
