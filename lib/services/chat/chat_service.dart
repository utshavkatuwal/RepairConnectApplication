import 'dart:async';
import '../../core/security/input_safety.dart';
import '../../core/network/dio_client.dart';
import '../../shared/models/models.dart';

/// Chat abstraction (§16): Flutter not coupled to WS provider.
/// Backend persists; WS pushes; HTTP polling fallback on reconnect.
abstract class ChatService {
  Stream<ChatMessage> stream(String conversationId);
  Future<List<ChatMessage>> history(String conversationId);
  Future<ChatMessage> send(String conversationId, String body);
  Future<void> markRead(String conversationId);
}

/// Dev/offline-capable in-memory impl with live broadcast stream.
class InMemoryChatService implements ChatService {
  final Map<String, List<ChatMessage>> _store = {};
  final Map<String, StreamController<ChatMessage>> _ctrls = {};

  StreamController<ChatMessage> _ctrl(String id) =>
      _ctrls.putIfAbsent(id, () => StreamController.broadcast());

  @override
  Stream<ChatMessage> stream(String conversationId) =>
      _ctrl(conversationId).stream;

  @override
  Future<List<ChatMessage>> history(String conversationId) async =>
      List.of(_store[conversationId] ?? []);

  @override
  Future<ChatMessage> send(String conversationId, String body) async {
    final clean = sanitizeText(body, max: 2000);
    if (clean.isEmpty) {
      throw ArgumentError('Message body required');
    }
    final m = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        conversationId: conversationId,
        senderId: 'me',
        body: clean,
        createdAt: DateTime.now().toIso8601String(),
        read: false);
    _store.putIfAbsent(conversationId, () => []).add(m);
    _ctrl(conversationId).add(m);
    return m;
  }

  @override
  Future<void> markRead(String conversationId) async {
    final list = _store[conversationId];
    if (list == null) return;
    _store[conversationId] = [
      for (final m in list)
        ChatMessage(
            id: m.id,
            conversationId: m.conversationId,
            senderId: m.senderId,
            body: m.body,
            createdAt: m.createdAt,
            read: true),
    ];
  }
}

/// Production HTTP impl: history/send/markRead via REST; stream() polls
/// with backoff and emits only new ids. Swap without touching UI.
class ApiChatService implements ChatService {
  final DioClient api;
  final Map<String, StreamController<ChatMessage>> _ctrls = {};
  final Map<String, bool> _polling = {};
  ApiChatService(this.api);

  @override
  Stream<ChatMessage> stream(String conversationId) {
    final c = _ctrls.putIfAbsent(
        conversationId, () => StreamController.broadcast());
    _poll(conversationId);
    return c.stream;
  }

  Future<void> _poll(String id) async {
    if (_polling[id] == true) return;
    _polling[id] = true;
    final seen = <String>{};
    var backoff = 2;
    while (_ctrls.containsKey(id) && !_ctrls[id]!.isClosed) {
      try {
        final h = await history(id);
        for (final m in h) {
          if (seen.add(m.id)) _ctrls[id]?.add(m);
        }
        backoff = 2;
      } catch (_) {
        backoff = (backoff * 2).clamp(2, 30);
      }
      await Future.delayed(Duration(seconds: backoff));
    }
    _polling[id] = false;
  }

  @override
  Future<List<ChatMessage>> history(String conversationId) async {
    try {
      final r = await api.getRetry(
          '/api/v1/conversations/$conversationId/messages');
      final body = Map<String, dynamic>.from(r.data as Map);
      return ApiResponseX.list(body, ChatMessage.fromJson);
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<ChatMessage> send(String conversationId, String body) async {
    try {
      final r = await api.dio.post(
          '/api/v1/conversations/$conversationId/messages',
          data: {'body': body});
      final d = Map<String, dynamic>.from(
          (Map<String, dynamic>.from(r.data as Map))['data'] as Map);
      return ChatMessage.fromJson(d);
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<void> markRead(String conversationId) async {
    try {
      await api.dio
          .post('/api/v1/conversations/$conversationId/read');
    } catch (e) {
      throw api.mapError(e);
    }
  }
}

// Minimal local envelope parser to avoid importing full envelope here.
class ApiResponseX {
  static List<T> list<T>(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) from) {
    final d = json['data'];
    final items = d is List ? d : (d is Map ? d['items'] ?? [] : []);
    return ((items ?? []) as List)
        .map((e) => from(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
