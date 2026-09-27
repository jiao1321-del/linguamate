class RoleplayMission {
  final String id;
  final String title;
  final String baseScenario;
  final String yourRole;
  final String shiliRole;
  final String goal;
  final String suggestedOpening;

  const RoleplayMission({
    required this.id,
    required this.title,
    required this.baseScenario,
    required this.yourRole,
    required this.shiliRole,
    required this.goal,
    required this.suggestedOpening,
  });

  String get backendScenario =>
      '任務｜$title｜你的角色：$yourRole｜Shili角色：$shiliRole｜目標：$goal';
}
