import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/features/payments/domain/payment_machine.dart';
import 'package:repairconnect/services/payments/payments_repo.dart';

void main() {
  test('payment transitions follow table', () {
    expect(PaymentMachine.canTransition('PENDING', 'PROCESSING'), true);
    expect(PaymentMachine.canTransition('PENDING', 'REFUNDED'), false);
    expect(PaymentMachine.canTransition('PROCESSING', 'SUCCEEDED'), true);
    expect(PaymentMachine.canTransition('SUCCEEDED', 'REFUNDED'), true);
    expect(PaymentMachine.canTransition('FAILED', 'PENDING'), true);
    expect(PaymentMachine.canTransition('REFUNDED', 'PENDING'), false);
  });

  test('amount validation guards', () {
    expect(PaymentMachine.validateAmount(0), isNotNull);
    expect(PaymentMachine.validateAmount(-5), isNotNull);
    expect(PaymentMachine.validateAmount(200000), isNotNull);
    expect(PaymentMachine.validateAmount(299), isNull);
  });

  test('refund requires succeeded + reason', () {
    expect(
        PaymentMachine.validateRefund('PENDING', 'valid reason here'),
        isNotNull);
    expect(PaymentMachine.validateRefund('SUCCEEDED', 'x'), isNotNull);
    expect(
        PaymentMachine.validateRefund('SUCCEEDED', 'customer moved'),
        isNull);
  });

  test('idempotency: same key returns same tx', () async {
    final repo = FakePaymentsRepository();
    final a = await repo.startPayment(
        bookingId: 'b1', amount: 100, idempotencyKey: 'k1');
    final b = await repo.startPayment(
        bookingId: 'b1', amount: 100, idempotencyKey: 'k1');
    expect(a['id'], b['id']);
    final c = await repo.startPayment(
        bookingId: 'b1', amount: 100, idempotencyKey: 'k2');
    expect(c['id'] != a['id'], true);
  });

  test('fake repo exposes transactions + invoice', () async {
    final repo = FakePaymentsRepository();
    await repo.startPayment(
        bookingId: 'b9', amount: 50, idempotencyKey: 'inv-k');
    expect((await repo.transactions('b9')).isNotEmpty, true);
    expect((await repo.invoice('b9'))?.bookingId, 'b9');
  });
}
