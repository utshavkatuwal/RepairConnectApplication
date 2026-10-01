import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/features/payments/domain/payment_machine.dart';
import 'helpers/fakes.dart';

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
        bookingId: 'b1', provider: 'sandbox', amount: 100, idempotencyKey: 'k1');
    final b = await repo.startPayment(
        bookingId: 'b1', provider: 'sandbox', amount: 100, idempotencyKey: 'k1');
    expect(a['id'], b['id']);
    final c = await repo.startPayment(
        bookingId: 'b1', provider: 'sandbox', amount: 100, idempotencyKey: 'k2');
    expect(c['id'] != a['id'], true);
  });

  test('fake repo exposes transactions + invoice', () async {
    final repo = FakePaymentsRepository();
    await repo.startPayment(
        bookingId: 'b9', provider: 'sandbox', amount: 50, idempotencyKey: 'inv-k');
    expect((await repo.transactions('b9')).isNotEmpty, true);
    expect((await repo.invoice('b9'))?.bookingId, 'b9');
  });

  test('bill lifecycle: none, create, issued amount kept', () async {
    final repo = FakePaymentsRepository();
    expect(await repo.bill('b7'), isNull);
    final bill = await repo.createBill(
        bookingId: 'b7', amount: 1500, notes: 'Parts + labour');
    expect(bill['status'], 'issued');
    expect(bill['amount'], 1500);
    expect((await repo.bill('b7'))?['status'], 'issued');
  });

  test('sandbox confirm flips server state', () async {
    final repo = FakePaymentsRepository();
    final tx = await repo.startPayment(
        bookingId: 'b8',
        provider: 'sandbox',
        amount: 100,
        idempotencyKey: 'cf-1');
    await repo.confirm('${tx['id']}');
    expect(await repo.status('${tx['id']}'), 'successful');
  });
}
