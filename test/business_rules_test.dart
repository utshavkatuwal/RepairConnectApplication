import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/core/constants/app_constants.dart';
import 'package:repairconnect/core/utils/validators.dart';

void main() {
  test('job state machine only allows valid transitions', () {
    expect(JobStatus.canTransition('REQUESTED', 'ACCEPTED'), true);
    expect(JobStatus.canTransition('REQUESTED', 'COMPLETED'), false);
    expect(JobStatus.canTransition('ACCEPTED', 'SCHEDULED'), true);
    expect(JobStatus.canTransition('IN_PROGRESS', 'COMPLETED'), true);
    expect(JobStatus.canTransition('COMPLETED', 'REQUESTED'), false);
    expect(JobStatus.canTransition('CANCELLED', 'ACCEPTED'), false);
  });

  test('validators reject bad input', () {
    expect(emailValidator('bad'), isNotNull);
    expect(emailValidator('a@b.co'), isNull);
    expect(passwordValidator('short'), isNotNull);
    expect(passwordValidator('longenough1'), isNull);
    expect(requiredValidator(''), isNotNull);
  });
}
