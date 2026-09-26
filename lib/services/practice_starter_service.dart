class PracticeStarter {
  final String text;
  final String chinese;

  const PracticeStarter({
    required this.text,
    required this.chinese,
  });
}

class PracticeStarterService {
  const PracticeStarterService._();

  static List<PracticeStarter> ideas({
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

  static const _freeTalk = <String, List<PracticeStarter>>{
    'English': [
      PracticeStarter(text: 'How was your day today?', chinese: '你今天過得怎麼樣？'),
      PracticeStarter(text: 'What have you been into lately?', chinese: '你最近在忙什麼／迷上什麼？'),
      PracticeStarter(
        text: 'Tell me something interesting that happened this week.',
        chinese: '跟我說說這週發生的一件有趣的事。',
      ),
    ],
    'Tagalog': [
      PracticeStarter(text: 'Kumusta ang araw mo today?', chinese: '你今天過得怎麼樣？'),
      PracticeStarter(
        text: 'Ano ang madalas mong ginagawa kapag free time?',
        chinese: '你有空的時候通常會做什麼？',
      ),
      PracticeStarter(
        text: 'May interesting bang nangyari sa’yo this week?',
        chinese: '你這週有發生什麼有趣的事嗎？',
      ),
    ],
    'Taglish': [
      PracticeStarter(
        text: 'How was your day? May interesting bang nangyari?',
        chinese: '你今天過得怎麼樣？有發生什麼有趣的事嗎？',
      ),
      PracticeStarter(
        text: 'Ano usually ginagawa mo kapag may free time ka?',
        chinese: '你有空的時候通常會做什麼？',
      ),
      PracticeStarter(
        text: 'Tell me something you’re excited about this week.',
        chinese: '跟我說一件你這週很期待的事。',
      ),
    ],
  };

  static const _dailyLife = <String, List<PracticeStarter>>{
    'English': [
      PracticeStarter(
        text: 'What do you usually do after work?',
        chinese: '你下班後通常會做什麼？',
      ),
      PracticeStarter(text: 'What did you eat today?', chinese: '你今天吃了什麼？'),
      PracticeStarter(
        text: 'What are your plans for the weekend?',
        chinese: '你週末有什麼計畫？',
      ),
    ],
    'Tagalog': [
      PracticeStarter(
        text: 'Ano ang ginagawa mo usually pagkatapos ng work?',
        chinese: '你下班後通常會做什麼？',
      ),
      PracticeStarter(text: 'Ano ang kinain mo today?', chinese: '你今天吃了什麼？'),
      PracticeStarter(
        text: 'Ano ang plano mo this weekend?',
        chinese: '你週末有什麼計畫？',
      ),
    ],
    'Taglish': [
      PracticeStarter(
        text: 'What do you usually do after work?',
        chinese: '你下班後通常會做什麼？',
      ),
      PracticeStarter(
        text: 'Ano kinain mo today? Was it good?',
        chinese: '你今天吃了什麼？好吃嗎？',
      ),
      PracticeStarter(
        text: 'May plans ka ba this weekend?',
        chinese: '你這週末有安排嗎？',
      ),
    ],
  };

  static const _workplace = <String, List<PracticeStarter>>{
    'English': [
      PracticeStarter(
        text: 'I need to give a quick progress update.',
        chinese: '我需要快速回報一下目前的進度。',
      ),
      PracticeStarter(
        text: 'There is a problem on the production line.',
        chinese: '生產線上出現了一個問題。',
      ),
      PracticeStarter(
        text: 'Could you help me check this issue?',
        chinese: '你可以幫我確認這個問題嗎？',
      ),
    ],
    'Tagalog': [
      PracticeStarter(
        text: 'Kailangan kong magbigay ng mabilis na progress update.',
        chinese: '我需要快速回報一下目前的進度。',
      ),
      PracticeStarter(
        text: 'May problema sa production line.',
        chinese: '生產線上出現了一個問題。',
      ),
      PracticeStarter(
        text: 'Pwede mo ba akong tulungang i-check itong issue?',
        chinese: '你可以幫我確認這個問題嗎？',
      ),
    ],
    'Taglish': [
      PracticeStarter(
        text: 'I need to give a quick progress update sa team.',
        chinese: '我需要跟團隊快速回報一下進度。',
      ),
      PracticeStarter(
        text: 'May issue sa production line. Can we check it together?',
        chinese: '生產線有問題，我們可以一起確認嗎？',
      ),
      PracticeStarter(
        text: 'Pwede mo ba akong tulungan with this issue?',
        chinese: '你可以幫我處理這個問題嗎？',
      ),
    ],
  };

  static const _travel = <String, List<PracticeStarter>>{
    'English': [
      PracticeStarter(text: 'I’d like to check in, please.', chinese: '我想辦理入住。'),
      PracticeStarter(
        text: 'Could you recommend a good local restaurant?',
        chinese: '你可以推薦一家不錯的當地餐廳嗎？',
      ),
      PracticeStarter(
        text: 'What’s the easiest way to get to the station?',
        chinese: '去車站最方便的方法是什麼？',
      ),
    ],
    'Tagalog': [
      PracticeStarter(text: 'Magche-check in po sana ako.', chinese: '我想辦理入住。'),
      PracticeStarter(
        text: 'May maire-recommend ba kayong magandang local restaurant?',
        chinese: '你可以推薦一家不錯的當地餐廳嗎？',
      ),
      PracticeStarter(
        text: 'Ano ang pinakamadaling paraan papunta sa station?',
        chinese: '去車站最方便的方法是什麼？',
      ),
    ],
    'Taglish': [
      PracticeStarter(text: 'Hi, magche-check in sana ako.', chinese: '嗨，我想辦理入住。'),
      PracticeStarter(
        text: 'Can you recommend a good local restaurant nearby?',
        chinese: '你可以推薦附近不錯的當地餐廳嗎？',
      ),
      PracticeStarter(
        text: 'Ano ang easiest way papunta sa station?',
        chinese: '去車站最方便的方法是什麼？',
      ),
    ],
  };
}
