class LearningCourseLesson {
  final String type;
  final String title;
  final String description;
  final String action;

  const LearningCourseLesson({
    required this.type,
    required this.title,
    required this.description,
    required this.action,
  });
}

class LearningCourseChapter {
  final String id;
  final String title;
  final String goal;
  final String focus;
  final List<LearningCourseLesson> lessons;

  const LearningCourseChapter({
    required this.id,
    required this.title,
    required this.goal,
    required this.focus,
    required this.lessons,
  });
}

class LearningCoursePlan {
  final String title;
  final String summary;
  final List<LearningCourseChapter> chapters;

  const LearningCoursePlan({
    required this.title,
    required this.summary,
    required this.chapters,
  });
}
