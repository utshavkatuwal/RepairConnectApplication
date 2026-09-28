import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode.dart';
import '../core/widgets/offline_banner.dart';
import 'router.dart';

class RepairConnectApp extends ConsumerWidget {
  const RepairConnectApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'RepairConnect™',
      debugShowCheckedModeBanner: false,
      theme: buildRepairLightTheme(),
      darkTheme: buildRepairTheme(),
      themeMode: mode,
      routerConfig: router,
      builder: (ctx, child) => Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child ?? const SizedBox()),
        ],
      ),
    );
  }
}
