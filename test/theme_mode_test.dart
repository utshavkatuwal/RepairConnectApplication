// ignore_for_file: unnecessary_underscores
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repairconnect/app/providers.dart';
import 'package:repairconnect/core/theme/app_theme.dart';
import 'package:repairconnect/core/theme/theme_mode.dart';
import 'package:repairconnect/core/widgets/rc_widgets.dart';
import 'package:repairconnect/features/customer/presentation/customer_screens.dart';
import 'package:repairconnect/theme.dart';
import 'helpers/fakes.dart';

void main() {
  test('theme mode defaults to dark and toggles', () async {
    final n = ThemeModeState();
    expect(n.state, ThemeMode.dark);
    await n.toggle();
    expect(n.state, ThemeMode.light);
    await n.toggle();
    expect(n.state, ThemeMode.dark);
  });

  test('light theme uses light surfaces spec', () {
    final t = buildRepairLightTheme();
    expect(t.brightness, Brightness.light);
    expect(t.scaffoldBackgroundColor,
        RepairColors.lightScaffold);
    expect(t.colorScheme.primary, RepairColors.lightTeal);
    expect(t.colorScheme.surface, RepairColors.lightSurface);
    final input = t.inputDecorationTheme;
    final focused = input.focusedBorder as OutlineInputBorder;
    expect(focused.borderRadius, BorderRadius.circular(6));
    expect(
        focused.borderSide.color, RepairColors.lightTeal);
  });

  test('mode helpers resolve per brightness', () {
    expect(RepairColors.lightInk.toARGB32(), 0xFF0F172A);
    expect(RepairColors.lightTeal.toARGB32(), 0xFF0E9DB2);
  });

  testWidgets('customer home renders in light mode without overflow',
      (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          catalogRepoProvider.overrideWithValue(FakeCatalogRepository()),
          notificationsRepoProvider
              .overrideWithValue(FakeNotificationsRepository()),
          locationServiceProvider
              .overrideWithValue(FakeLocationService()),
        ],
        child: MaterialApp(
            theme: buildRepairLightTheme(),
            home: const CustomerHomeScreen())));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('What needs repair?'), findsOneWidget);
    expect(find.text('Verified technicians'), findsOneWidget);
  });

  testWidgets('key screens hold at phone width (360px)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final errors = <String>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      errors.add(d.toString());
    };
    await tester.pumpWidget(ProviderScope(
        overrides: [
          catalogRepoProvider.overrideWithValue(FakeCatalogRepository()),
          notificationsRepoProvider
              .overrideWithValue(FakeNotificationsRepository()),
          locationServiceProvider
              .overrideWithValue(FakeLocationService()),
        ],
        child: MaterialApp(
            theme: buildRepairTheme(),
            home: const CustomerHomeScreen())));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    FlutterError.onError = old;
    expect(find.text('What needs repair?'), findsOneWidget);
    expect(errors, isEmpty);
  });

  testWidgets('back button falls back when stack is empty',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
            path: '/home',
            builder: (_, __) =>
                const Scaffold(body: Text('HOME'))),
        GoRoute(
            path: '/detail',
            builder: (_, __) => const Scaffold(
                appBar: RcBackAppBar(
                    title: 'Detail', fallback: '/home'),
                body: Text('DETAIL'))),
      ],
    );
    await tester.pumpWidget(
        MaterialApp.router(routerConfig: router));
    expect(find.text('DETAIL'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('back button pops when stack exists',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
            path: '/home',
            builder: (_, s) => Scaffold(
                body: Center(
                    child: Builder(builder: (ctx) {
              return TextButton(
                  onPressed: () =>
                      GoRouter.of(ctx).push('/detail'),
                  child: const Text('OPEN'));
            })))),
        GoRoute(
            path: '/detail',
            builder: (_, __) => const Scaffold(
                appBar: RcBackAppBar(
                    title: 'Detail', fallback: '/home'),
                body: Text('DETAIL'))),
      ],
    );
    await tester.pumpWidget(
        MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    expect(find.text('DETAIL'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('OPEN'), findsOneWidget);
  });
}
