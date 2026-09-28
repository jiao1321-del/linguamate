class RoleplayMission {
  final String id;
  final String title;
  final String baseScenario;
  final String yourRole;
  final String shiliRole;
  final String goal;
  final String suggestedOpening;
  final List<String> stages;

  const RoleplayMission({
    required this.id,
    required this.title,
    required this.baseScenario,
    required this.yourRole,
    required this.shiliRole,
    required this.goal,
    required this.suggestedOpening,
    this.stages = const <String>[],
  });

  int get completionTurns => stages.isEmpty ? 4 : stages.length;

  String stageForTurn(int userTurns) {
    if (stages.isEmpty) {
      if (userTurns <= 1) return '開場';
      if (userTurns <= 3) return '互動';
      return '收尾';
    }
    final index = userTurns.clamp(0, stages.length - 1).toInt();
    return stages[index];
  }

  String branchForMessage(String message) {
    final normalized = message.toLowerCase();
    const problemWords = <String>[
      'problem',
      'issue',
      'wrong',
      'delay',
      'cannot',
      "can't",
      'not available',
      'sorry',
      'error',
    ];
    const clarifyWords = <String>[
      'why',
      'how',
      'what',
      'could you',
      'can you',
      'please explain',
      '?',
    ];

    if (problemWords.any(normalized.contains)) return '問題處理分支';
    if (clarifyWords.any(normalized.contains)) return '追問澄清分支';
    return '順利推進分支';
  }

  String backendScenarioFor({
    required int userTurns,
    required String learnerMessage,
  }) {
    final stage = stageForTurn(userTurns);
    final branch = branchForMessage(learnerMessage);
    return '任務｜$title｜你的角色：$yourRole｜Shili角色：$shiliRole｜'
        '目標：$goal｜目前階段：$stage｜劇情分支：$branch｜'
        '請依學習者這一輪的實際回答改變後續情境，不要照固定台詞走。';
  }

  String get backendScenario => backendScenarioFor(
        userTurns: 0,
        learnerMessage: '',
      );
}
