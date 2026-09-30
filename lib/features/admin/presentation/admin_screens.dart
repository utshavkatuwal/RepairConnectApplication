// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_mode.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../theme.dart';
import 'admin_extra_screens.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    const nav = [
      (AppRoutes.adminUsers, 'Users', Icons.people_outline),
      (AppRoutes.adminVerify, 'Verification', Icons.verified_outlined),
      (AppRoutes.adminServices, 'Services', Icons.build_outlined),
      (AppRoutes.adminJobs, 'Jobs', Icons.work_outline),
      (AppRoutes.adminPayments, 'Payments', Icons.payments_outlined),
      (AppRoutes.adminComplaints, 'Complaints', Icons.support_agent_outlined),
      (AppRoutes.adminAudit, 'Audit logs', Icons.history),
    ];
    return Scaffold(
      appBar: AppBar(title: Text('Admin — Secure console'), actions: [
        IconButton(
            tooltip: 'Toggle light/dark',
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(mode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined)),
      ]),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.watch(adminRepoProvider).dashboard(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return AsyncStateView(
                loading: false,
                failure: snap.error,
                onRetry: () =>
                    (context as Element).markNeedsBuild(),
                onLogin: () async {
                  await ref
                      .read(authProvider.notifier)
                      .expire();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
                child: const SizedBox());
          }
          final d = snap.data ?? {};
          final stats = [
            ('Users', '${d['users'] ?? 0}'),
            ('Active jobs', '${d['active_jobs'] ?? 0}'),
            ('Revenue', '\$${d['revenue'] ?? 0}'),
            ('Pending verification',
                '${d['pending_verification'] ?? 0}'),
          ];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6),
                itemCount: stats.length,
                itemBuilder: (_, i) => RcCard(
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                      Text(stats[i].$1,
                          style: TextStyle(
                              fontSize: 11,
                              color: RepairColors.mutedOn(
                                  context))),
                      Text(stats[i].$2,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: RepairColors.headingOn(
                                  context))),
                    ])),
              ),
              const SizedBox(height: 12),
              Text('MANAGE',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: RepairColors.tealOn(context))),
              const SizedBox(height: 8),
              for (final n in nav)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RcCard(
                    onTap: () => context.go(n.$1),
                    child: Row(children: [
                      Icon(n.$3,
                          size: 18,
                          color:
                              RepairColors.tealOn(context)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(n.$2,
                              style: TextStyle(
                                  color: RepairColors.headingOn(
                                      context)))),
                      Icon(Icons.chevron_right,
                          size: 16,
                          color:
                              RepairColors.mutedOn(context)),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),
              const AdminReviewsNote(),
              const SizedBox(height: 8),
              Text(
                  'Admin actions are authorized server-side and written to audit_logs (who/what/target/time).',
                  style: TextStyle(
                      fontSize: 11,
                      color: RepairColors.mutedOn(context))),
            ],
          );
        },
      ),
    );
  }
}
