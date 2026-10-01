import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/app/providers.dart';
import 'package:repairconnect/features/bookings/presentation/booking_screens.dart';

import 'helpers/fakes.dart';

/// Device repro: opening a JOB detail (Booking #1) red-screened with
/// `_elements.contains(element)` (framework.dart:2170 — GlobalKey retake).
void main() {
  testWidgets('job detail screen builds without framework assertion',
      (tester) async {
    final payments = FakePaymentsRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        bookingsRepoProvider.overrideWithValue(FakeBookingsRepository()),
        paymentsRepoProvider.overrideWithValue(payments),
        reviewsRepoProvider.overrideWithValue(FakeReviewsRepository()),
      ],
      child: const MaterialApp(
          home: BookingDetailScreen(id: '1')),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Booking #1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
