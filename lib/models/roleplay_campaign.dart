class RoleplayCampaignChapter {
  final String id;
  final String title;
  final String subtitle;
  final String missionId;

  const RoleplayCampaignChapter({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.missionId,
  });
}

class RoleplayCampaign {
  final String id;
  final String title;
  final String description;
  final List<RoleplayCampaignChapter> chapters;

  const RoleplayCampaign({
    required this.id,
    required this.title,
    required this.description,
    required this.chapters,
  });

  static const overseasWork = RoleplayCampaign(
    id: 'overseas-work',
    title: '海外工作篇',
    description: '從面試一路走到跨部門協作與客戶應對，把工作英文變成連續劇情。',
    chapters: <RoleplayCampaignChapter>[
      RoleplayCampaignChapter(
        id: 'interview',
        title: 'Chapter 1 · 面試',
        subtitle: '自我介紹、工作經驗與追問',
        missionId: 'work-interview',
      ),
      RoleplayCampaignChapter(
        id: 'first-day',
        title: 'Chapter 2 · 第一天上班',
        subtitle: '認識同事、確認工作內容與需求',
        missionId: 'work-first-day',
      ),
      RoleplayCampaignChapter(
        id: 'progress',
        title: 'Chapter 3 · 進度會議',
        subtitle: '簡短回報進度、卡點與下一步',
        missionId: 'work-progress',
      ),
      RoleplayCampaignChapter(
        id: 'incident',
        title: 'Chapter 4 · 設備異常',
        subtitle: '向主管報告問題、影響與改善方案',
        missionId: 'work-incident',
      ),
      RoleplayCampaignChapter(
        id: 'cross-team',
        title: 'Chapter 5 · 跨部門協作',
        subtitle: '釐清責任、時程與交付',
        missionId: 'work-cross-team',
      ),
      RoleplayCampaignChapter(
        id: 'customer',
        title: 'Chapter 6 · 客戶抱怨',
        subtitle: '理解問題、回應質疑並提出處理方案',
        missionId: 'work-customer',
      ),
    ],
  );
}
