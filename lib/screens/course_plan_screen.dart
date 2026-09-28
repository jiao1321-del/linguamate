import 'package:flutter/material.dart';

import '../models/learning_course.dart';

class CoursePlanScreen extends StatefulWidget {
  final LearningCoursePlan plan;
  final Set<String> initialCompleted;
  final Future<Set<String>> Function(String chapterId) onCompleteChapter;
  final ValueChanged<String>? onAction;

  const CoursePlanScreen({
    super.key,
    required this.plan,
    required this.initialCompleted,
    required this.onCompleteChapter,
    this.onAction,
  });

  @override
  State<CoursePlanScreen> createState() => _CoursePlanScreenState();
}

class _CoursePlanScreenState extends State<CoursePlanScreen> {
  late Set<String> _completed;

  @override
  void initState() {
    super.initState();
    _completed = {...widget.initialCompleted};
  }

  bool _unlocked(int index) {
    if (index == 0) return true;
    return _completed.contains(widget.plan.chapters[index - 1].id);
  }

  Future<void> _complete(LearningCourseChapter chapter) async {
    final updated = await widget.onCompleteChapter(chapter.id);
    if (!mounted) return;
    setState(() => _completed = {...updated});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 個人課程 2.0')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Card(
            key: const ValueKey('v135-course-overview'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.plan.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.plan.summary),
                  const SizedBox(height: 8),
                  const Text(
                    '每章包含：素材 → 句型 → 口說 → 情境 → 小測驗。完成本章後才解鎖下一章。',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < widget.plan.chapters.length; index++)
            _ChapterCard(
              chapter: widget.plan.chapters[index],
              unlocked: _unlocked(index),
              completed: _completed.contains(
                widget.plan.chapters[index].id,
              ),
              onAction: widget.onAction,
              onComplete: () => _complete(widget.plan.chapters[index]),
            ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final LearningCourseChapter chapter;
  final bool unlocked;
  final bool completed;
  final ValueChanged<String>? onAction;
  final VoidCallback onComplete;

  const _ChapterCard({
    required this.chapter,
    required this.unlocked,
    required this.completed,
    required this.onAction,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('course-chapter-${chapter.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Opacity(
          opacity: unlocked ? 1 : 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    completed
                        ? Icons.verified_rounded
                        : unlocked
                            ? Icons.menu_book_rounded
                            : Icons.lock_outline_rounded,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chapter.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(chapter.goal),
              const SizedBox(height: 10),
              for (final lesson in chapter.lessons)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.arrow_right_rounded),
                  title: Text(
                    '${lesson.title} · ${chapter.focus}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(lesson.description),
                  trailing: IconButton(
                    onPressed:
                        unlocked ? () => onAction?.call(lesson.action) : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: unlocked && !completed ? onComplete : null,
                  icon: Icon(
                    completed
                        ? Icons.check_rounded
                        : Icons.lock_open_rounded,
                  ),
                  label: Text(completed ? '本章已完成' : '完成本章並解鎖下一章'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
