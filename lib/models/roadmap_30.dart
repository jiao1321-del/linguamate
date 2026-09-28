class Roadmap30Day {
  final int day;
  final int week;
  final String title;
  final String focus;
  final String action;
  final bool checkpoint;

  const Roadmap30Day({
    required this.day,
    required this.week,
    required this.title,
    required this.focus,
    required this.action,
    this.checkpoint = false,
  });
}

class Roadmap30Plan {
  final String goal;
  final String title;
  final String summary;
  final List<Roadmap30Day> days;

  const Roadmap30Plan({
    required this.goal,
    required this.title,
    required this.summary,
    required this.days,
  });
}
