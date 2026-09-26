class PracticeStarterService {
  const PracticeStarterService._();

  static List<String> ideas({
    required String language,
    required String scenario,
  }) {
    final group = switch (scenario) {
      '日常生活' => _dailyLife,
      '工作職場' => _workplace,
      '旅行' => _travel,
      _ => _freeTalk,
    };

    return group[language] ?? group['English']!;
  }

  static const _freeTalk = <String, List<String>>{
    'English': [
      'How was your day today?',
      'What have you been into lately?',
      'Tell me something interesting that happened this week.',
    ],
    'Tagalog': [
      'Kumusta ang araw mo today?',
      'Ano ang madalas mong ginagawa kapag free time?',
      'May interesting bang nangyari sa’yo this week?',
    ],
    'Taglish': [
      'How was your day? May interesting bang nangyari?',
      'Ano usually ginagawa mo kapag may free time ka?',
      'Tell me something you’re excited about this week.',
    ],
  };

  static const _dailyLife = <String, List<String>>{
    'English': [
      'What do you usually do after work?',
      'What did you eat today?',
      'What are your plans for the weekend?',
    ],
    'Tagalog': [
      'Ano ang ginagawa mo usually pagkatapos ng work?',
      'Ano ang kinain mo today?',
      'Ano ang plano mo this weekend?',
    ],
    'Taglish': [
      'What do you usually do after work?',
      'Ano kinain mo today? Was it good?',
      'May plans ka ba this weekend?',
    ],
  };

  static const _workplace = <String, List<String>>{
    'English': [
      'I need to give a quick progress update.',
      'There is a problem on the production line.',
      'Could you help me check this issue?',
    ],
    'Tagalog': [
      'Kailangan kong magbigay ng mabilis na progress update.',
      'May problema sa production line.',
      'Pwede mo ba akong tulungang i-check itong issue?',
    ],
    'Taglish': [
      'I need to give a quick progress update sa team.',
      'May issue sa production line. Can we check it together?',
      'Pwede mo ba akong tulungan with this issue?',
    ],
  };

  static const _travel = <String, List<String>>{
    'English': [
      'I’d like to check in, please.',
      'Could you recommend a good local restaurant?',
      'What’s the easiest way to get to the station?',
    ],
    'Tagalog': [
      'Magche-check in po sana ako.',
      'May maire-recommend ba kayong magandang local restaurant?',
      'Ano ang pinakamadaling paraan papunta sa station?',
    ],
    'Taglish': [
      'Hi, magche-check in sana ako.',
      'Can you recommend a good local restaurant nearby?',
      'Ano ang easiest way papunta sa station?',
    ],
  };
}
