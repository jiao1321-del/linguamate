import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/learning_item.dart';
import '../services/backup_codec.dart';

class BackupScreen extends StatefulWidget {
  final List<LearningItem> items;
  final Future<void> Function(List<LearningItem> items) onRestore;

  const BackupScreen({
    super.key,
    required this.items,
    required this.onRestore,
  });

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _backupController = TextEditingController();
  bool _isRestoring = false;

  @override
  void dispose() {
    _backupController.dispose();
    super.dispose();
  }

  Future<void> _copyBackup() async {
    final backupCode = BackupCodec.encode(widget.items);
    await Clipboard.setData(ClipboardData(text: backupCode));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '已複製 ${widget.items.length} 筆學習資料的備份碼 ✅',
        ),
      ),
    );
  }

  Future<void> _restoreBackup() async {
    final raw = _backupController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先貼上 LinguaMate 備份碼。')),
      );
      return;
    }

    late final List<LearningItem> restoredItems;
    try {
      restoredItems = BackupCodec.decode(raw);
    } on FormatException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('還原學習資料？'),
        content: Text(
          '這份備份包含 ${restoredItems.length} 筆資料。\n\n'
          '還原後會取代目前 App 內的收藏、分類與複習進度。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('確認還原'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);

    try {
      await widget.onRestore(restoredItems);
      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '已還原 ${restoredItems.length} 筆學習資料 🎉',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('還原失敗，原本資料沒有變更。')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('備份與還原')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '建立備份',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '目前共有 ${widget.items.length} 筆學習資料。'
                      '備份會包含收藏、分類與 SRS 複習進度。',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _copyBackup,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('複製備份碼'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '建議把備份碼貼到自己的備忘錄、雲端筆記或其他安全的位置。',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restore_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '還原備份',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '把之前保存的 LinguaMate 備份碼貼到下方。',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _backupController,
                      minLines: 5,
                      maxLines: 9,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        hintText: 'LINGUAMATE_BACKUP_V1:...',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isRestoring ? null : _restoreBackup,
                        icon: _isRestoring
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.settings_backup_restore_rounded),
                        label: Text(
                          _isRestoring ? '還原中...' : '還原這份備份',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Card(
              child: ListTile(
                contentPadding: EdgeInsets.all(18),
                leading: Icon(Icons.info_outline_rounded),
                title: Text('備份碼不會上傳到伺服器'),
                subtitle: Text(
                  'V0.9 的備份完全在你的裝置上產生與還原。'
                  '請自行保管備份碼；拿到備份碼的人可以讀取其中的學習資料。',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
