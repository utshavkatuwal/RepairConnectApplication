import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/core/constants/app_constants.dart';
import 'package:repairconnect/features/bookings/domain/job_machine.dart';

void main() {
  test('actor matrix: tech progresses, customer cancels', () {
    expect(
        JobMachine.canActor(
            role: AppRoles.technician,
            from: JobStatus.requested,
            to: JobStatus.accepted),
        true);
    expect(
        JobMachine.canActor(
            role: AppRoles.customer,
            from: JobStatus.requested,
            to: JobStatus.accepted),
        false);
    expect(
        JobMachine.canActor(
            role: AppRoles.customer,
            from: JobStatus.requested,
            to: JobStatus.cancelled),
        true);
    expect(
        JobMachine.canActor(
            role: AppRoles.technician,
            from: JobStatus.inProgress,
            to: JobStatus.completed),
        true);
    expect(
        JobMachine.canActor(
            role: AppRoles.customer,
            from: JobStatus.inProgress,
            to: JobStatus.completed),
        false);
  });

  test('admin can do all valid transitions', () {
    for (final from in JobStatus.transitions.keys) {
      for (final to in JobStatus.transitions[from]!) {
        expect(
            JobMachine.canActor(
                role: AppRoles.admin, from: from, to: to),
            true,
            reason: '$from -> $to');
      }
    }
  });

  test('cancel/dispute require reason', () {
    expect(JobMachine.requiresReason(JobStatus.cancelled), true);
    expect(JobMachine.requiresReason(JobStatus.disputed), true);
    expect(JobMachine.requiresReason(JobStatus.completed), false);
    expect(
        JobMachine.validateReason(JobStatus.cancelled, 'x'),
        isNotNull);
    expect(
        JobMachine.validateReason(
            JobStatus.cancelled, 'customer moved away'),
        isNull);
  });

  test('terminal states documented', () {
    expect(JobMachine.isTerminal(JobStatus.cancelled), true);
    expect(JobMachine.isTerminal(JobStatus.disputed), true);
    expect(JobMachine.isTerminal(JobStatus.completed), false);
  });

  test('nextFor lists role actions', () {
    expect(
        JobMachine.nextFor(AppRoles.customer, JobStatus.requested),
        [JobStatus.cancelled]);
    expect(
        JobMachine.nextFor(AppRoles.technician, JobStatus.accepted),
        contains(JobStatus.enRoute));
    expect(
        JobMachine.nextFor(AppRoles.technician, JobStatus.accepted),
        isNot(contains(JobStatus.scheduled)));
  });
}
