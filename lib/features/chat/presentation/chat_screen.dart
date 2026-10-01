// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../shared/models/models.dart';
import '../../../theme.dart';

/// Customer/technician persistent conversation (§16): job context header,
/// timestamps, read receipts, per-message retry, live stream + reconnect.
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatState();
}

class _ChatState extends ConsumerState<ChatScreen> {
  final _c = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _msgs = [];
  bool _loading = true;
  Object? _err;
  bool _sending = false;
  String? _failed;
  StreamSubscription<ChatMessage>? _sub;
  bool _live = false;

  String? _cid;

  String get _bookingId {
    final id = widget.conversationId;
    return id.startsWith('conv-') ? id.substring(5) : id;
  }

  /// Numeric conversation id: resolves `conv-{booking}` via the backend.
  Future<String> _resolveId() async {
    if (_cid != null) return _cid!;
    final raw = widget.conversationId;
    if (!raw.startsWith('conv-')) {
      _cid = raw;
      return raw;
    }
    final r = await ref
        .read(dioClientProvider)
        .getRetry('/api/v1/jobs/$_bookingId/conversation');
    final body = Map<String, dynamic>.from(r.data as Map);
    final data = body['data'];
    final id = data is Map ? '${data['id']}' : '';
    if (id.isEmpty) throw Exception('No conversation for this job yet.');
    _cid = id;
    return id;
  }

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final id = await _resolveId();
      if (!mounted) return;
      _sub = ref.read(chatServiceProvider).stream(id).listen((m) {
        if (!mounted) return;
        setState(() {
          _live = true;
          if (!_msgs.any((e) => e.id == m.id)) {
            _msgs = [..._msgs, m];
          }
        });
        _jump();
      }, onError: (_) {
        if (mounted) setState(() => _live = false);
      });
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() {
          _err = e;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scroll.dispose();
    _c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final id = await _resolveId();
      final svc = ref.read(chatServiceProvider);
      final h = await svc.history(id);
      await svc.markRead(id);
      if (!mounted) return;
      setState(() => _msgs = h);
      _jump();
    } catch (e) {
      if (mounted) setState(() => _err = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _jump() {
    if (!_scroll.hasClients || _msgs.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final t = _c.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _failed = null;
    });
    try {
      final id = await _resolveId();
      final m =
          await ref.read(chatServiceProvider).send(id, t);
      if (!mounted) return;
      setState(() {
        _c.clear();
        if (!_msgs.any((e) => e.id == m.id)) {
          _msgs = [..._msgs, m];
        }
      });
      _jump();
      ref.read(chatServiceProvider).markRead(id);
    } catch (e) {
      if (mounted) {
        setState(() => _failed = t);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(
                    '${AppRoutes.bookingDetail}/$_bookingId');
              }
            },
          ),
          title: Row(children: [
        Expanded(child: Text('Chat • $_bookingId')),
        Icon(_live ? Icons.bolt : Icons.bolt_outlined,
            size: 14,
            color: _live
                ? RepairColors.tealOn(context)
                : RepairColors.faintOn(context)),
      ])),
      body: Column(
        children: [
          InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context
                    .go('${AppRoutes.bookingDetail}/$_bookingId');
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 9),
              decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: RepairColors.borderSoft))),
              child: Row(
                children: [
                  Icon(Icons.work_outline,
                      size: 14,
                      color: RepairColors.tealOn(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Job context — tap to open booking',
                        style: TextStyle(
                            fontSize: 12,
                            color: RepairColors.bodyOn(context))),
                  ),
                  Icon(Icons.chevron_right,
                      size: 14,
                      color: RepairColors.faintOn(context)),
                ],
              ),
            ),
          ),
          if (_failed != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: RepairColors.redBg,
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Send failed — message kept.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white)),
                  ),
                  TextButton(
                      onPressed: () {
                        _c.text = _failed!;
                        setState(() => _failed = null);
                        _send();
                      },
                      child: Text('Retry')),
                ],
              ),
            ),
          Expanded(
            child: AsyncStateView(
              loading: _loading,
              failure: _err,
              empty: _msgs.isEmpty,
              emptyText:
                  'No messages yet. Say hello — history persists.',
              onRetry: _load,
              onLogin: () async {
                await ref.read(authProvider.notifier).expire();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _msgs.length,
                itemBuilder: (_, i) {
                  final m = _msgs[i];
                  final mine = m.senderId == 'me';
                  return Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin:
                          const EdgeInsets.only(bottom: 8),
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                      constraints: const BoxConstraints(
                          maxWidth: 280),
                      decoration: BoxDecoration(
                        color: mine
                            ? RepairColors.chatMine
                            : RepairColors.chatTheirs,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text(m.body,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13)),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_stamp(m.createdAt),
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: RepairColors
                                          .faint)),
                              if (mine) ...[
                                const SizedBox(width: 4),
                                Icon(
                                    m.read
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 11,
                                    color: m.read
                                        ? RepairColors
                                            .tealBright
                                        : RepairColors.faint),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                        controller: _c,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                            hintText: 'Message…'),
                        onSubmitted: (_) => _send()),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stamp(String iso) {
    if (iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}
