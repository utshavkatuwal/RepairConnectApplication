import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repairconnect/app/app.dart';
import 'package:repairconnect/features/design_system/presentation/design_system_screen.dart';

void main() {
  testWidgets('RepairConnect design system loads', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
        const ProviderScope(child: DesignSystemCheck()));
    await tester.pump();

    expect(find.textContaining('Repair'), findsWidgets);
    expect(find.textContaining('BUTTON SYSTEM'), findsOneWidget);
    expect(find.textContaining('Telemetry'), findsWidgets);
  });

  testWidgets('Router app boots to landing/splash', (WidgetTester tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: RepairConnectApp()));
    await tester.pump();
    // Flush splash's session-restore timeout timer before teardown.
    await tester.pump(const Duration(seconds: 9));
    await tester.pump();
    // Splash redirects; either splash, landing, or login must appear.
    expect(
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
            find.textContaining('Repair').evaluate().isNotEmpty ||
            find.textContaining('Log').evaluate().isNotEmpty,
        true);
  });
}

class DesignSystemCheck extends StatelessWidget {
  const DesignSystemCheck({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: DesignSystemScreen());
  }
}
