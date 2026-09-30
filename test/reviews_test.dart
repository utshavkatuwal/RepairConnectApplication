import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/core/constants/app_constants.dart';
import 'package:repairconnect/core/errors/failures.dart';
import 'package:repairconnect/features/reviews/data/reviews_repo.dart';
import 'helpers/fakes.dart';

void main() {
  test('rating and comment validation', () {
    expect(ReviewRules.validateRating(0), isNotNull);
    expect(ReviewRules.validateRating(6), isNotNull);
    expect(ReviewRules.validateRating(5), isNull);
    expect(ReviewRules.validateComment('x' * 1001), isNotNull);
    expect(ReviewRules.validateComment(null), isNull);
  });

  test('eligibility requires completed + participant', () {
    expect(
        ReviewRules.validateEligibility(
            bookingStatus: JobStatus.inProgress,
            isParticipant: true),
        isNotNull);
    expect(
        ReviewRules.validateEligibility(
            bookingStatus: JobStatus.completed,
            isParticipant: false),
        isNotNull);
    expect(
        ReviewRules.validateEligibility(
            bookingStatus: JobStatus.completed,
            isParticipant: true),
        isNull);
  });

  test('one review per booking, edit and delete', () async {
    final repo = FakeReviewsRepository();
    final r = await repo.submit(
        bookingId: 'b1', rating: 5, comment: 'great');
    expect(r.rating, 5);
    await expectLater(repo.submit(bookingId: 'b1', rating: 4),
        throwsA(isA<Failure>()));
    final upd =
        await repo.update(r.id, rating: 4, comment: 'good');
    expect(upd.rating, 4);
    await repo.remove(r.id);
    expect(await repo.forBooking('b1'), isEmpty);
  });

  test('report requires reason', () async {
    final repo = FakeReviewsRepository();
    final r = await repo.submit(bookingId: 'b2', rating: 2);
    await expectLater(
        repo.report(r.id, 'x'), throwsA(isA<Failure>()));
    await repo.report(r.id, 'inappropriate content here');
  });
}
