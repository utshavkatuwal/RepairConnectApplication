import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/core/auth/role_guards.dart';
import 'package:repairconnect/core/constants/app_constants.dart';
import 'package:repairconnect/core/utils/validators.dart';
import 'helpers/fakes.dart';
import 'package:repairconnect/features/bookings/domain/job_machine.dart';
import 'package:repairconnect/features/reviews/data/reviews_repo.dart';
import 'package:repairconnect/services/notifications/push_service.dart';
import 'package:repairconnect/shared/models/models.dart';

/// Cross-module flows with fake backends (Â§27 integration level):
/// customer booking, technician job, payment verification, review gating.
void main() {
  test('customer booking flow: request to completed to review', () {
    // 1. Request validated client-side.
    expect(descriptionValidator('short'), isNotNull);
    expect(
        descriptionValidator(
            'Washer makes grinding noise on spin cycle'),
        isNull);
    // 2. State path walkable by the right actors.
    var s = JobStatus.requested;
    expect(
        JobMachine.canActor(
            role: AppRoles.technician, from: s, to: JobStatus.accepted),
        true);
    s = JobStatus.accepted;
    // Backend real chain: accepted -> technician_arriving -> in_progress
    // -> completed (no scheduled/arrived job states).
    for (final next in [
      JobStatus.enRoute,
      JobStatus.inProgress,
      JobStatus.completed,
    ]) {
      expect(
          JobMachine.canActor(
              role: AppRoles.technician, from: s, to: next),
          true,
          reason: '$s -> $next');
      s = next;
    }
    expect(
        JobMachine.canActor(
            role: AppRoles.technician,
            from: JobStatus.accepted,
            to: JobStatus.scheduled),
        false,
        reason: 'scheduled hop does not exist on the backend');
    // 3. Review unlocks only now, for participants.
    expect(
        ReviewRules.validateEligibility(
            bookingStatus: s, isParticipant: true),
        isNull);
    expect(
        ReviewRules.validateEligibility(
            bookingStatus: JobStatus.inProgress,
            isParticipant: true),
        isNotNull);
  });

  test('technician flow gated by verification', () async {
    const pending = User(
        id: 't',
        name: 'T',
        email: 't@x.co',
        role: AppRoles.technician,
        techVerified: false,
        techStatus: 'PENDING');
    expect(techAcceptAllowed(pending), false);
    expect(
        guardRoute(AppRoutes.techRequests, pending), isNull);
    // Pending tech sees requests but Accept disabled (UI gate);
    // machine still requires verified path server-side in prod.
  });

  test('payment flow: start, verify, notify, no client trust',
      () async {
    final pay = FakePaymentsRepository();
    final center =
        NotificationCenter(FakeNotificationsRepository());
    final tx = await pay.startPayment(
        bookingId: 'b1',
        provider: 'sandbox',
        amount: 299,
        idempotencyKey: newIdempotencyKey());
    expect(tx['status'], 'initiated');
    // Client must re-query server state, never assume success.
    final verified = await pay.status('${tx['id']}');
    expect(verified, 'initiated');
    center.record(
        type: NotificationTypes.payment,
        title: 'Payment $verified',
        body: 'b1');
    expect(await center.unreadCount(), 2);
  });

  test('auth flow: role derivation to home to guard', () {
    final role = devRoleForEmail('tech@x.co');
    expect(homeForRole(role), AppRoutes.techDashboard);
    const tech = User(
        id: 'u',
        name: 'T',
        email: 'tech@x.co',
        role: AppRoles.technician);
    expect(guardRoute(AppRoutes.adminDashboard, tech),
        AppRoutes.customerHome);
    expect(guardRoute(AppRoutes.techDashboard, tech), isNull);
  });

  test('chat persists within booking context', () async {
    final chat = InMemoryChatService();
    await chat.send('conv-b1', 'Technician is en route');
    await chat.send('conv-b1', 'Arrived at gate');
    final h = await chat.history('conv-b1');
    expect(h.length, 2);
    expect(h.every((m) => m.conversationId == 'conv-b1'), true);
    await chat.markRead('conv-b1');
    expect((await chat.history('conv-b1')).every((m) => m.read),
        true);
  });

  test('cancellation carries reason and notifies', () async {
    expect(JobMachine.validateReason(JobStatus.cancelled, 'x'),
        isNotNull);
    const reason = 'Customer rescheduled to next week';
    expect(
        JobMachine.validateReason(JobStatus.cancelled, reason),
        isNull);
    final center =
        NotificationCenter(FakeNotificationsRepository());
    center.record(
        type: NotificationTypes.booking,
        title: 'Booking CANCELLED',
        body: reason);
    final all = await center.all();
    expect(all.first.type, NotificationTypes.booking);
  });
}
