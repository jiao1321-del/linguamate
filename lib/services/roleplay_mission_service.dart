import '../models/roleplay_mission.dart';

class RoleplayMissionService {
  const RoleplayMissionService._();

  static const missions = <RoleplayMission>[
    RoleplayMission(
      id: 'work-incident',
      title: '向主管報告異常',
      baseScenario: '工作職場',
      yourRole: '現場工程師',
      shiliRole: '主管',
      goal: '清楚說明發生什麼事、影響範圍，以及你需要的協助。',
      suggestedOpening: 'I need to report an issue on the production line.',
      stages: <String>[
        '說明異常',
        '回答影響範圍',
        '回應主管追問',
        '提出改善與需求',
      ],
    ),
    RoleplayMission(
      id: 'work-progress',
      title: '會議進度回報',
      baseScenario: '工作職場',
      yourRole: '專案成員',
      shiliRole: '會議主持人',
      goal: '用簡短自然的方式說明目前進度、卡點與下一步。',
      suggestedOpening: 'Let me give you a quick progress update.',
      stages: <String>[
        '說明目前進度',
        '解釋卡點',
        '回應追問',
        '確認下一步',
      ],
    ),
    RoleplayMission(
      id: 'airport-checkin',
      title: '機場報到',
      baseScenario: '旅行',
      yourRole: '旅客',
      shiliRole: '航空公司地勤',
      goal: '完成報到、確認行李與登機資訊。',
      suggestedOpening: 'Hi, I’d like to check in for my flight.',
      stages: <String>[
        '確認航班',
        '處理證件與座位',
        '確認行李',
        '取得登機資訊',
      ],
    ),
    RoleplayMission(
      id: 'work-interview',
      title: '海外工作面試',
      baseScenario: '工作職場',
      yourRole: '求職者',
      shiliRole: '面試主管',
      goal: '自然完成自我介紹、說明經驗並回答追問。',
      suggestedOpening: 'Thank you for giving me this opportunity.',
      stages: <String>[
        '自我介紹',
        '說明工作經驗',
        '回答能力追問',
        '詢問職務與收尾',
      ],
    ),
    RoleplayMission(
      id: 'work-first-day',
      title: '第一天上班',
      baseScenario: '工作職場',
      yourRole: '新進同事',
      shiliRole: '資深同事',
      goal: '認識同事、確認流程並主動詢問工作需求。',
      suggestedOpening: 'Hi, it’s my first day here. Nice to meet you.',
      stages: <String>[
        '打招呼與介紹',
        '確認工作內容',
        '詢問流程與工具',
        '確認今天下一步',
      ],
    ),
    RoleplayMission(
      id: 'work-cross-team',
      title: '跨部門協作',
      baseScenario: '工作職場',
      yourRole: '專案負責人',
      shiliRole: '其他部門窗口',
      goal: '釐清責任、時程、需求與交付內容。',
      suggestedOpening: 'Can we align on the timeline and responsibilities?',
      stages: <String>[
        '確認共同目標',
        '釐清責任',
        '協調時程',
        '確認交付與追蹤',
      ],
    ),
    RoleplayMission(
      id: 'work-customer',
      title: '回應客戶抱怨',
      baseScenario: '工作職場',
      yourRole: '問題處理窗口',
      shiliRole: '客戶',
      goal: '理解抱怨、確認影響、回應質疑並提出處理方案。',
      suggestedOpening: 'I understand your concern. Let me confirm what happened.',
      stages: <String>[
        '理解客戶問題',
        '確認影響',
        '回應質疑',
        '提出處理與追蹤方案',
      ],
    ),
    RoleplayMission(
      id: 'hotel-checkin',
      title: '飯店入住',
      baseScenario: '旅行',
      yourRole: '旅客',
      shiliRole: '飯店櫃台',
      goal: '完成入住並確認早餐、退房時間與房間資訊。',
      suggestedOpening: 'Hi, I have a reservation under my name.',
      stages: <String>[
        '確認訂房',
        '核對入住資訊',
        '詢問設施',
        '確認退房與需求',
      ],
    ),
    RoleplayMission(
      id: 'restaurant',
      title: '餐廳點餐',
      baseScenario: '日常生活',
      yourRole: '客人',
      shiliRole: '服務人員',
      goal: '自然完成點餐，並詢問推薦或餐點內容。',
      suggestedOpening: 'Could you recommend something popular here?',
      stages: <String>[
        '詢問推薦',
        '確認餐點內容',
        '處理加點或限制',
        '完成點餐',
      ],
    ),
    RoleplayMission(
      id: 'friend-chat',
      title: '朋友日常聊天',
      baseScenario: '日常生活',
      yourRole: '朋友',
      shiliRole: '你的朋友',
      goal: '聊近況、追問細節，並自然延續至少幾個回合。',
      suggestedOpening: 'How have you been lately?',
      stages: <String>[
        '聊近況',
        '追問細節',
        '分享自己的事',
        '自然延續或收尾',
      ],
    ),
  ];

  static RoleplayMission? byId(String? id) {
    if (id == null) return null;
    for (final mission in missions) {
      if (mission.id == id) return mission;
    }
    return null;
  }
}
