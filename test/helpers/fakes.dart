// TEST-ONLY fakes. Never referenced by application runtime code —
// providers.dart wires the Api* implementations. These exist so unit,
// widget, and flow tests run hermetically without a backend.
import 'dart:async';

import 'package:repairconnect/core/constants/app_constants.dart';
import 'package:repairconnect/core/errors/failures.dart';
import 'package:repairconnect/core/security/input_safety.dart';
import 'package:repairconnect/core/network/dio_client.dart';
import 'package:repairconnect/core/storage/session_store.dart';
import 'package:repairconnect/features/marketplace/data/repos.dart';
import 'package:repairconnect/services/chat/chat_service.dart';
import 'package:repairconnect/services/location/location_service.dart';
import 'package:repairconnect/services/notifications/push_service.dart';
import 'package:repairconnect/services/payments/payments_repo.dart';
import 'package:repairconnect/features/reviews/data/reviews_repo.dart';
import 'package:repairconnect/shared/models/models.dart';

/// Test-only role derivation formerly in AuthRepository. Production roles
/// always come from the authenticated backend user.
String devRoleForEmail(String email) {
  final e = email.toLowerCase();
  if (e.contains('admin')) return AppRoles.admin;
  if (e.contains('tech')) return AppRoles.technician;
  return AppRoles.customer;
}

DioClient _testDio() => DioClient(sessions: SessionStore());

class FakeCatalogRepository extends CatalogRepository {
  FakeCatalogRepository() : super(_testDio());

  @override
  Future<List<Category>> categories({bool force = false}) async =>
      const [
        Category(id: 'c1', name: 'Appliance'),
        Category(id: 'c2', name: 'Medical Devices'),
      ];

  @override
  Future<List<Technician>> technicians(
          {String? q,
          String? categoryId,
          double? lat,
          double? lng}) async =>
      const [
        Technician(
            id: 't1',
            userId: 'u-t1',
            name: 'Test Tech One',
            specialty: 'Appliance',
            rating: 4.9,
            jobsCompleted: 10,
            verified: true,
            available: true),
      ];

  @override
  Future<List<ServiceRequest>> openRequests() async => [];
}

class FakeLocationService implements LocationService {
  @override
  Future<bool> ensurePermission() async => true;
  @override
  Future<LatLng?> currentPosition() async =>
      const LatLng(27.7172, 85.3240);
  @override
  Future<List<TechnicianNearby>> nearbyTechnicians(
          {required double lat,
          required double lng,
          String? categoryId}) async =>
      const [];
  @override
  Future<String?> resolveAddress(double lat, double lng) async =>
      'Test address';
}

class FakePaymentsRepository implements PaymentsRepository {
  final Map<String, String> _states = {};
  final Map<String, List<Transaction>> _txs = {};
  final Map<String, Map<String, dynamic>> _bills = {};

  @override
  Future<Map<String, dynamic>> startPayment(
          {required String bookingId,
          required String provider,
          required double amount,
          required String idempotencyKey}) async =>
      {
        'id': 'tx_$idempotencyKey',
        'booking_id': bookingId,
        'provider': provider,
        'amount': amount,
        'status': _states.putIfAbsent(idempotencyKey, () => 'initiated'),
      };

  @override
  Future<Map<String, dynamic>> confirm(String paymentId) async {
    for (final key in _states.keys.toList()) {
      if ('tx_$key' == paymentId) {
        _states[key] = 'successful';
        return {'id': paymentId, 'status': 'successful'};
      }
    }
    throw Exception('Payment not found');
  }

  @override
  Future<Map<String, dynamic>?> bill(String bookingId) async =>
      _bills[bookingId];

  @override
  Future<Map<String, dynamic>> createBill(
          {required String bookingId,
          required double amount,
          String? notes,
          List<Map<String, dynamic>>? lineItems}) async =>
      _bills[bookingId] = {
        'id': 'bill-$bookingId',
        'job_id': bookingId,
        'amount': amount,
        'notes': notes,
        'line_items': lineItems,
        'status': 'issued',
      };

  @override
  Future<String> status(String transactionId) async {
    for (final e in _states.entries) {
      if ('tx_${e.key}' == transactionId) return e.value;
    }
    return 'initiated';
  }

  @override
  Future<List<Transaction>> transactions(String bookingId) async =>
      List.of(_txs[bookingId] ??
          [
            Transaction(
                id: 'tx-seed-1',
                paymentId: 'tx-seed-1',
                kind: 'CHARGE',
                amount: 299),
          ]);

  @override
  Future<Invoice?> invoice(String bookingId) async => Invoice(
      id: 'inv-$bookingId',
      bookingId: bookingId,
      total: 299,
      issuedAt: DateTime.now().toIso8601String());

  @override
  Future<String> refund(String transactionId, String reason) async {
    for (final e in _states.entries) {
      if ('tx_${e.key}' == transactionId) {
        if (e.value != 'SUCCEEDED') {
          throw Exception('Only succeeded payments can be refunded');
        }
        _states[e.key] = 'REFUNDED';
        return 'REFUNDED';
      }
    }
    throw Exception('Transaction not found');
  }
}

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

class FakeNotificationsRepository implements NotificationsRepository {
  final List<AppNotification> _items = [
    AppNotification(
        id: 'n1',
        type: 'BOOKING',
        title: 'Request accepted',
        body: 'Dr. Keith Sterling accepted IPC-9028-T.',
        read: false,
        createdAt: '2025-10-24T09:00:00Z'),
    AppNotification(
        id: 'n2',
        type: 'SYSTEM',
        title: 'Calibration locked',
        body: 'Asset IRC-8102 certificate cryptographically locked.',
        read: true,
        createdAt: '2025-10-23T10:00:00Z'),
  ];
  @override
  Future<List<AppNotification>> list(
          {int page = 1, int perPage = 20}) async =>
      _items.skip((page - 1) * perPage).take(perPage).toList();
  @override
  Future<void> markRead(String id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final n = _items[i];
    _items[i] = AppNotification(
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        read: true,
        createdAt: n.createdAt);
  }
}

class FakeReviewsRepository implements ReviewsRepository {
  final Map<String, Review> _byBooking = {};
  int _seq = 0;

  @override
  Future<Review> submit(
      {required String bookingId,
      required int rating,
      String? comment}) async {
    final clean =
        comment == null ? null : sanitizeText(comment, max: 1000);
    final rErr = ReviewRules.validateRating(rating) ??
        ReviewRules.validateComment(clean);
    if (rErr != null) throw ValidationFailure(rErr);
    if (_byBooking.containsKey(bookingId)) {
      throw const ValidationFailure('This booking already has a review');
    }
    _seq++;
    final r = Review(
        id: 'rev-$_seq',
        bookingId: bookingId,
        rating: rating,
        comment: clean);
    _byBooking[bookingId] = r;
    return r;
  }

  @override
  Future<List<Review>> forBooking(String bookingId) async =>
      [if (_byBooking[bookingId] != null) _byBooking[bookingId]!];

  @override
  Future<List<Review>> forTechnician(String technicianId) async =>
      _byBooking.values.toList();

  @override
  Future<Review> update(String id,
      {int? rating, String? comment}) async {
    final e = _byBooking.entries
        .where((x) => x.value.id == id)
        .toList();
    if (e.isEmpty) throw const NotFoundFailure('Review not found');
    if (rating != null) {
      final err = ReviewRules.validateRating(rating);
      if (err != null) throw ValidationFailure(err);
    }
    final cleanComment =
        comment == null ? null : sanitizeText(comment, max: 1000);
    if (comment != null) {
      final err = ReviewRules.validateComment(cleanComment);
      if (err != null) throw ValidationFailure(err);
    }
    final old = e.first.value;
    final upd = Review(
        id: old.id,
        bookingId: old.bookingId,
        rating: rating ?? old.rating,
        comment: cleanComment ?? old.comment);
    _byBooking[e.first.key] = upd;
    return upd;
  }

  @override
  Future<void> remove(String id) async {
    _byBooking.removeWhere((_, v) => v.id == id);
  }

  @override
  Future<void> report(String id, String reason) async {
    final clean = sanitizeText(reason, max: 1000);
    if (clean.length < 5) {
      throw const ValidationFailure('Report reason required (min 5)');
    }
  }
}
