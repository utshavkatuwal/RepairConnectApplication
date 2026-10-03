import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/app/providers.dart';
import 'package:repairconnect/core/theme/app_theme.dart';
import 'package:repairconnect/features/customer/presentation/customer_screens.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('discovery screen renders at 360px without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final errors = <String>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.toString());
    await tester.pumpWidget(ProviderScope(
        overrides: [
          catalogRepoProvider.overrideWithValue(FakeCatalogRepository()),
          locationServiceProvider
              .overrideWithValue(FakeLocationService()),
        ],
        child: MaterialApp(
            theme: buildRepairLightTheme(),
            home: const DiscoveryScreen())));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    FlutterError.onError = old;
    expect(find.text('Find technicians'), findsOneWidget);
    expect(errors, isEmpty, reason: errors.join('\n'));
  });
}
