import 'dart:async';
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
