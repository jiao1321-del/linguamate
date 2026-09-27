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
    ),
    RoleplayMission(
      id: 'work-progress',
      title: '會議進度回報',
      baseScenario: '工作職場',
      yourRole: '專案成員',
      shiliRole: '會議主持人',
      goal: '用簡短自然的方式說明目前進度、卡點與下一步。',
      suggestedOpening: 'Let me give you a quick progress update.',
    ),
    RoleplayMission(
      id: 'airport-checkin',
      title: '機場報到',
      baseScenario: '旅行',
      yourRole: '旅客',
      shiliRole: '航空公司地勤',
      goal: '完成報到、確認行李與登機資訊。',
      suggestedOpening: 'Hi, I’d like to check in for my flight.',
    ),
    RoleplayMission(
      id: 'hotel-checkin',
      title: '飯店入住',
      baseScenario: '旅行',
      yourRole: '旅客',
      shiliRole: '飯店櫃台',
      goal: '完成入住並確認早餐、退房時間與房間資訊。',
      suggestedOpening: 'Hi, I have a reservation under my name.',
    ),
    RoleplayMission(
      id: 'restaurant',
      title: '餐廳點餐',
      baseScenario: '日常生活',
      yourRole: '客人',
      shiliRole: '服務人員',
      goal: '自然完成點餐，並詢問推薦或餐點內容。',
      suggestedOpening: 'Could you recommend something popular here?',
    ),
    RoleplayMission(
      id: 'friend-chat',
      title: '朋友日常聊天',
      baseScenario: '日常生活',
      yourRole: '朋友',
      shiliRole: '你的朋友',
      goal: '聊近況、追問細節，並自然延續至少幾個回合。',
      suggestedOpening: 'How have you been lately?',
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
