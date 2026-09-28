enum CloudSyncPhase {
  signedOut,
  idle,
  syncing,
  synced,
  offline,
  error,
}

class CloudSyncStatus {
  final CloudSyncPhase phase;
  final DateTime? lastSyncedAt;
  final String message;
  final String email;

  const CloudSyncStatus({
    required this.phase,
    this.lastSyncedAt,
    this.message = '',
    this.email = '',
  });

  const CloudSyncStatus.signedOut()
      : phase = CloudSyncPhase.signedOut,
        lastSyncedAt = null,
        message = '尚未登入雲端帳號',
        email = '';

  String get label => switch (phase) {
        CloudSyncPhase.signedOut => '尚未登入',
        CloudSyncPhase.idle => '等待同步',
        CloudSyncPhase.syncing => '同步中…',
        CloudSyncPhase.synced => '已同步 ☁️',
        CloudSyncPhase.offline => '離線 · 保留本機資料',
        CloudSyncPhase.error => '同步異常',
      };
}
