import 'package:flutter/material.dart';

import '../models/cloud_session.dart';
import '../models/cloud_sync_status.dart';
import '../services/cloud_sync_service.dart';

class CloudSyncScreen extends StatefulWidget {
  final CloudSyncService service;
  final Future<Map<String, dynamic>> Function() exportLocal;
  final Future<void> Function(Map<String, dynamic> payload) importCloud;
  final CloudSyncStatus status;
  final bool autoSyncEnabled;
  final Future<void> Function(bool enabled) onAutoSyncChanged;
  final Future<void> Function() onSyncNow;

  const CloudSyncScreen({
    super.key,
    required this.service,
    required this.exportLocal,
    required this.importCloud,
    this.status = const CloudSyncStatus.signedOut(),
    this.autoSyncEnabled = true,
    required this.onAutoSyncChanged,
    required this.onSyncNow,
  });

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  CloudSession? _session;
  bool _loading = true;
  bool _busy = false;
  late bool _autoSyncEnabled;
  String? _message;

  @override
  void initState() {
    super.initState();
    _autoSyncEnabled = widget.autoSyncEnabled;
    _restore();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final session = await widget.service.loadSession();
    if (!mounted) return;
    setState(() {
      _session = session;
      _loading = false;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() => _run(() async {
        final session = await widget.service.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;
        setState(() {
          _session = session;
          _message = '登入成功。';
        });
      });

  Future<void> _signUp() => _run(() async {
        final session = await widget.service.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (!mounted) return;
        setState(() {
          _session = session;
          _message = session == null
              ? '帳號已建立。若專案啟用 Email 驗證，請先完成信箱驗證後再登入。'
              : '帳號已建立並登入。';
        });
      });

  Future<void> _upload() => _run(() async {
        final session = _session;
        if (session == null) return;
        final payload = await widget.exportLocal();
        await widget.service.upload(session: session, payload: payload);
        if (!mounted) return;
        setState(() => _message = '本機學習資料已同步到雲端 ☁️');
      });

  Future<void> _download() => _run(() async {
        final session = _session;
        if (session == null) return;
        final payload = await widget.service.download(session);
        if (payload == null) {
          if (!mounted) return;
          setState(() => _message = '雲端目前沒有可還原的學習資料。');
          return;
        }
        await widget.importCloud(payload);
        if (!mounted) return;
        setState(() => _message = '雲端資料已還原到這台裝置。');
      });

  Future<void> _syncNow() => _run(() async {
        await widget.onSyncNow();
        if (!mounted) return;
        setState(() => _message = '已完成雙向合併同步 ☁️');
      });

  Future<void> _toggleAutoSync(bool enabled) async {
    setState(() => _autoSyncEnabled = enabled);
    await widget.onAutoSyncChanged(enabled);
    if (!mounted) return;
    setState(() {
      _message = enabled ? '已開啟自動同步。' : '已關閉自動同步。';
    });
  }

  Future<void> _signOut() => _run(() async {
        await widget.service.signOut();
        if (!mounted) return;
        setState(() {
          _session = null;
          _message = '已登出。';
        });
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('雲端帳號與同步')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                Card(
                  key: const ValueKey('v136-cloud-sync-card'),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'V1.37 · Cloud Sync 2.0',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _session == null
                              ? '登入後可同步收藏、錯題、能力、訓練歷史、口說紀錄、課程進度與 Shili 對話。'
                              : '已登入：${_session!.email}',
                        ),
                        const SizedBox(height: 14),
                        if (_session == null) ...[
                          TextField(
                            key: const ValueKey('cloud-email'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            key: const ValueKey('cloud-password'),
                            controller: _passwordController,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: '密碼'),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  key: const ValueKey('cloud-sign-in'),
                                  onPressed: _busy ? null : _signIn,
                                  child: const Text('登入'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  key: const ValueKey('cloud-sign-up'),
                                  onPressed: _busy ? null : _signUp,
                                  child: const Text('建立帳號'),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4EEFF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_done_outlined),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.status.lastSyncedAt == null
                                        ? widget.status.label
                                        : '${widget.status.label} · ${widget.status.lastSyncedAt!.toLocal()}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SwitchListTile(
                            key: const ValueKey('cloud-auto-sync-toggle'),
                            contentPadding: EdgeInsets.zero,
                            title: const Text('自動同步'),
                            subtitle: const Text(
                              'App 啟動與學習資料變更後自動雙向合併',
                            ),
                            value: _autoSyncEnabled,
                            onChanged: _busy ? null : _toggleAutoSync,
                          ),
                          FilledButton.icon(
                            key: const ValueKey('cloud-sync-now'),
                            onPressed: _busy ? null : _syncNow,
                            icon: const Icon(Icons.sync_rounded),
                            label: const Text('現在合併同步'),
                          ),
                          const SizedBox(height: 8),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text('進階同步操作'),
                            children: [
                              FilledButton.tonalIcon(
                                key: const ValueKey('cloud-upload'),
                                onPressed: _busy ? null : _upload,
                                icon: const Icon(Icons.cloud_upload_outlined),
                                label: const Text('強制上傳本機資料'),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.tonalIcon(
                                key: const ValueKey('cloud-download'),
                                onPressed: _busy ? null : _download,
                                icon: const Icon(Icons.cloud_download_outlined),
                                label: const Text('從雲端還原到此裝置'),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _busy ? null : _signOut,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('登出'),
                          ),
                        ],
                        if (_busy) ...[
                          const SizedBox(height: 12),
                          const LinearProgressIndicator(),
                        ],
                        if (_message != null) ...[
                          const SizedBox(height: 12),
                          Text(_message!),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '雲端資料受 Supabase Row Level Security 保護。自動同步會依 ID 與時間戳合併收藏、錯題、能力、口說、課程、RPG 與 30 天路線；離線時保留本機資料，恢復連線後再同步。',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
