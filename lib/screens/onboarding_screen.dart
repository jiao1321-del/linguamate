import 'package:flutter/material.dart';

typedef OnboardingFinish = Future<void> Function(
  String language,
  String goal,
);

class OnboardingScreen extends StatefulWidget {
  final String initialLanguage;
  final String initialGoal;
  final VoidCallback onOpenCloud;
  final OnboardingFinish onFinish;
  final Future<void> Function() onSkip;

  const OnboardingScreen({
    super.key,
    this.initialLanguage = 'English',
    this.initialGoal = '日常英文',
    required this.onOpenCloud,
    required this.onFinish,
    required this.onSkip,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _languages = <String>[
    'English',
    'Tagalog',
    'Taglish',
  ];

  static const _goals = <String>[
    '日常英文',
    '工作英文',
    '旅遊英文',
    'Tagalog 日常',
    'Taglish',
    '面試英文',
    '會議／報告英文',
  ];

  final _controller = PageController();
  int _page = 0;
  bool _busy = false;
  late String _language;
  late String _goal;

  @override
  void initState() {
    super.initState();
    _language = _languages.contains(widget.initialLanguage)
        ? widget.initialLanguage
        : 'English';
    _goal = _goals.contains(widget.initialGoal)
        ? widget.initialGoal
        : '日常英文';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page >= 4) {
      await _finish();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onFinish(_language, _goal);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onSkip();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 12, 4),
              child: Row(
                children: [
                  const Text(
                    'LinguaMate',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    key: const ValueKey('onboarding-skip'),
                    onPressed: _busy ? null : _skip,
                    child: const Text('稍後再設定'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                key: const ValueKey('onboarding-pages'),
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _WelcomePage(color: color),
                  const _InstallPage(),
                  _CloudPage(onOpenCloud: widget.onOpenCloud),
                  _LearningSetupPage(
                    language: _language,
                    goal: _goal,
                    languages: _languages,
                    goals: _goals,
                    onLanguageChanged: (value) {
                      setState(() => _language = value);
                    },
                    onGoalChanged: (value) {
                      setState(() {
                        _goal = value;
                        if (value == 'Tagalog 日常') {
                          _language = 'Tagalog';
                        } else if (value == 'Taglish') {
                          _language = 'Taglish';
                        }
                      });
                    },
                  ),
                  _ReadyPage(
                    language: _language,
                    goal: _goal,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 5; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: i == _page ? 22 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _page
                                ? color
                                : const Color(0xFFD8D1E3),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('onboarding-next'),
                      onPressed: _busy ? null : _next,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Text(
                          _page == 4 ? '開始第一堂課 ✨' : '下一步',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final Color color;

  const _WelcomePage({required this.color});

  @override
  Widget build(BuildContext context) {
    return _OnboardingBody(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE8E1F2),
                width: 4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/shili_avatar_v14.jpg',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '歡迎來到 LinguaMate',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Shili 會依你的程度、錯題、口說與學習進度，安排下一個最值得練的內容。',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.55),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FeatureChip(icon: Icons.auto_awesome_rounded, label: 'AI 教練'),
              _FeatureChip(icon: Icons.mic_none_rounded, label: '口說練習'),
              _FeatureChip(icon: Icons.cloud_done_outlined, label: '雲端同步'),
              _FeatureChip(icon: Icons.insights_outlined, label: '學習分析'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstallPage extends StatelessWidget {
  const _InstallPage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingBody(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIcon(icon: Icons.add_to_home_screen_rounded),
          SizedBox(height: 20),
          _PageTitle(
            title: '先把 LinguaMate 放到桌面',
            subtitle: '加入主畫面後，之後就能像一般 App 一樣直接打開。',
          ),
          SizedBox(height: 20),
          _InstructionCard(
            icon: Icons.phone_iphone_rounded,
            title: 'iPhone / iPad',
            text: 'Safari 開啟 → 分享 →「加入主畫面」→ 新增',
          ),
          SizedBox(height: 10),
          _InstructionCard(
            icon: Icons.android_rounded,
            title: 'Android',
            text: 'Chrome 開啟 → ⋮ →「新增至主畫面」或「安裝應用程式」',
          ),
          SizedBox(height: 14),
          Text(
            '這一步可以略過，不影響學習功能。',
            style: TextStyle(color: Color(0xFF756B82)),
          ),
        ],
      ),
    );
  }
}

class _CloudPage extends StatelessWidget {
  final VoidCallback onOpenCloud;

  const _CloudPage({required this.onOpenCloud});

  @override
  Widget build(BuildContext context) {
    return _OnboardingBody(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepIcon(icon: Icons.cloud_sync_outlined),
          const SizedBox(height: 20),
          const _PageTitle(
            title: '每個人都用自己的帳號',
            subtitle: '不要共用帳號，這樣 Shili 的記憶、錯題、XP 和課程才不會混在一起。',
          ),
          const SizedBox(height: 20),
          const _InstructionCard(
            icon: Icons.person_add_alt_1_rounded,
            title: '建立 LinguaMate Cloud',
            text: '用自己的 Email 建立帳號；之後換手機也能把學習進度同步回來。',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('onboarding-open-cloud'),
              onPressed: onOpenCloud,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('現在建立／登入帳號'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '也可以先開始學習，之後再到「我的 → LinguaMate Cloud」建立帳號。',
            style: TextStyle(
              color: Color(0xFF756B82),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningSetupPage extends StatelessWidget {
  final String language;
  final String goal;
  final List<String> languages;
  final List<String> goals;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onGoalChanged;

  const _LearningSetupPage({
    required this.language,
    required this.goal,
    required this.languages,
    required this.goals,
    required this.onLanguageChanged,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingBody(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepIcon(icon: Icons.tune_rounded),
          const SizedBox(height: 20),
          const _PageTitle(
            title: '設定你的學習方向',
            subtitle: '先選主要語言和目標，之後都可以再修改。',
          ),
          const SizedBox(height: 20),
          const Text(
            '主要語言',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in languages)
                ChoiceChip(
                  key: ValueKey('onboarding-language-$item'),
                  label: Text(item),
                  selected: language == item,
                  onSelected: (_) => onLanguageChanged(item),
                ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            key: const ValueKey('onboarding-goal'),
            initialValue: goal,
            decoration: const InputDecoration(
              labelText: '學習目標',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final item in goals)
                DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
            ],
            onChanged: (value) {
              if (value != null) onGoalChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _ReadyPage extends StatelessWidget {
  final String language;
  final String goal;

  const _ReadyPage({
    required this.language,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingBody(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _StepIcon(icon: Icons.rocket_launch_rounded),
          const SizedBox(height: 22),
          Text(
            '準備好了！',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '$language · $goal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 20),
          const _InstructionCard(
            icon: Icons.mic_none_rounded,
            title: '第一次使用口說',
            text: '瀏覽器詢問麥克風或語音辨識權限時，請選「允許」。',
          ),
          const SizedBox(height: 10),
          const _InstructionCard(
            icon: Icons.auto_awesome_rounded,
            title: '第一堂從 Shili 開始',
            text: '先和 Shili 聊幾句，系統會開始建立你的個人學習資料與每日訓練。',
          ),
        ],
      ),
    );
  }
}

class _OnboardingBody extends StatelessWidget {
  final Widget child;

  const _OnboardingBody({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 210,
        ),
        child: child,
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PageTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            height: 1.5,
            color: Color(0xFF655D70),
          ),
        ),
      ],
    );
  }
}

class _StepIcon extends StatelessWidget {
  final IconData icon;

  const _StepIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE5F8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(
        icon,
        size: 34,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InstructionCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E3F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}
