import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/core/errors/failures.dart';
import 'package:repairconnect/core/widgets/rc_widgets.dart';

Widget wrap(Widget w) =>
    MaterialApp(home: Scaffold(body: w));

void main() {
  testWidgets('loading shows spinner, hides child',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const AsyncStateView(
        loading: true, child: Text('CHILD'))));
    expect(find.byType(CircularProgressIndicator),
        findsOneWidget);
    expect(find.text('CHILD'), findsNothing);
  });

  testWidgets('empty shows message + icon',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const AsyncStateView(
        loading: false,
        empty: true,
        emptyText: 'Nothing booked yet.',
        child: Text('CHILD'))));
    expect(find.text('Nothing booked yet.'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('plain error shows retry',
      (WidgetTester tester) async {
    var retried = false;
    await tester.pumpWidget(wrap(AsyncStateView(
        loading: false,
        error: 'Boom failed.',
        onRetry: () => retried = true,
        child: const Text('CHILD'))));
    expect(find.text('Boom failed.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, true);
  });

  testWidgets('offline failure shows wifi icon',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const AsyncStateView(
        loading: false,
        failure: NetworkFailure(
            'No connection to server. Retry when online.'),
        child: Text('CHILD'))));
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });

  testWidgets('auth failure shows login action',
      (WidgetTester tester) async {
    var logged = false;
    await tester.pumpWidget(wrap(AsyncStateView(
        loading: false,
        failure: const AuthFailure('Session expired'),
        onLogin: () => logged = true,
        child: const Text('CHILD'))));
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    await tester.tap(find.text('Log in again'));
    expect(logged, true);
  });

  testWidgets('not-found shows search icon',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const AsyncStateView(
        loading: false,
        failure: NotFoundFailure('Technician not found.'),
        child: Text('CHILD'))));
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });

  testWidgets('RcButton variants render + tap',
      (WidgetTester tester) async {
    var tapped = 0;
    await tester.pumpWidget(wrap(Column(
      children: [
        RcButton(
            label: 'Go', onPressed: () => tapped++),
        const RcButton(label: 'Busy', loading: true),
        RcButton(
            label: 'Off', outline: true, onPressed: () {}),
        RcButton(
            label: 'Danger',
            destructive: true,
            onPressed: () {}),
        RcButton(label: 'Dead', onPressed: null),
      ],
    )));
    expect(find.text('Go'), findsOneWidget);
    expect(
        find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Go'));
    expect(tapped, 1);
  });

  testWidgets('RcField shows label + validates',
      (WidgetTester tester) async {
    final c = TextEditingController();
    final f = GlobalKey<FormState>();
    await tester.pumpWidget(wrap(Form(
      key: f,
      child: RcField(
          label: 'EMAIL',
          controller: c,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Required' : null),
    )));
    expect(find.text('EMAIL'), findsWidgets);
    expect(f.currentState!.validate(), false);
    c.text = 'a@b.co';
    expect(f.currentState!.validate(), true);
  });
}
