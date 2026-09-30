import 'dart:async';
import '../../core/network/dio_client.dart';
import '../../shared/models/models.dart';

/// Notifications (§17): server-stored, FCM-pushed. Modular handler for
/// foreground/background; no Firebase secrets in repo.
///
/// Types: BOOKING, REQUEST, MESSAGE, PAYMENT, REVIEW, SYSTEM, ADMIN.
class NotificationTypes {
  static const booking = 'BOOKING';
  static const request = 'REQUEST';
  static const message = 'MESSAGE';
  static const payment = 'PAYMENT';
  static const review = 'REVIEW';
  static const system = 'SYSTEM';
  static const admin = 'ADMIN';
  static const all = [
    booking,
    request,
    message,
    payment,
    review,
    system,
    admin
  ];
}

abstract class PushService {
  Future<String?> token();
  Stream<AppNotification> foreground();
}

class NoopPushService implements PushService {
  @override
  Future<String?> token() async => null;
  @override
  Stream<AppNotification> foreground() => const Stream.empty();
}

/// FCM bootstrap contract (credentials-gated). When google-services config
/// + firebase_messaging are added, this wires:
/// - foreground: onMessage → NotificationCenter.record
/// - background: onBackgroundMessage → server fetch on open
/// - token: getToken → POST /api/v1/devices (auth) for server push.
/// Until then it safely no-ops; the in-app center still works offline.
class PushBootstrap {
  final PushService push;
  final DioClient api;
  PushBootstrap({required this.push, required this.api});

  StreamSubscription<AppNotification>? _sub;

  Future<void> start(
      {required void Function(AppNotification) onForeground}) async {
    try {
      final t = await push.token();
      if (t != null && t.isNotEmpty) {
        try {
          await api.dio.post('/api/v1/devices',
              data: {'token': t, 'platform': 'flutter'});
        } catch (_) {}
      }
    } catch (_) {}
    _sub = push.foreground().listen(onForeground);
  }

  Future<void> stop() async => _sub?.cancel();
}

/// In-app notification center: server list plus locally-recorded domain
/// events (booking/payment/review) merged, unread-counted, streamed to UI.
/// The server list is the source of truth; local records reflect actions
/// the user just took in this session.
class NotificationCenter {
  final NotificationsRepository repo;
  final _ctrl = StreamController<AppNotification>.broadcast();
  final List<AppNotification> _local = [];

  NotificationCenter(this.repo);

  Stream<AppNotification> get stream => _ctrl.stream;

  void record(
      {required String type,
      required String title,
      required String body}) {
    assert(NotificationTypes.all.contains(type), 'unknown type $type');
    final n = AppNotification(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        title: title,
        body: body,
        read: false,
        createdAt: DateTime.now().toIso8601String());
    _local.insert(0, n);
    _ctrl.add(n);
  }

  void ingest(AppNotification n) {
    _local.insert(0, n);
    _ctrl.add(n);
  }

  Future<List<AppNotification>> all() async {
    final server = await repo.list(perPage: 50);
    final ids = server.map((e) => e.id).toSet();
    return [..._local.where((e) => !ids.contains(e.id)), ...server];
  }

  Future<int> unreadCount() async =>
      (await all()).where((e) => !e.read).length;

  Future<void> markRead(String id) async {
    final i = _local.indexWhere((e) => e.id == id);
    if (i >= 0) {
      final n = _local[i];
      _local[i] = AppNotification(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          read: true,
          createdAt: n.createdAt);
    }
    await repo.markRead(id);
  }

  static List<AppNotification> filterByType(
      List<AppNotification> items, String? type) {
    if (type == null) return items;
    return items.where((e) => e.type == type).toList();
  }
}

abstract class NotificationsRepository {
  Future<List<AppNotification>> list({int page = 1, int perPage = 20});
  Future<void> markRead(String id);
}

class ApiNotificationsRepository implements NotificationsRepository {
  final DioClient api;
  ApiNotificationsRepository(this.api);
  @override
  Future<List<AppNotification>> list(
      {int page = 1, int perPage = 20}) async {
    try {
      final r = await api.getRetry('/api/v1/notifications',
          query: {'page': page, 'per_page': perPage});
      final body = Map<String, dynamic>.from(r.data as Map);
      return ApiResponse.list(body, AppNotification.fromJson);
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await api.dio.post('/api/v1/notifications/$id/read');
    } catch (e) {
      throw api.mapError(e);
    }
  }
}
