// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/auth/role_guards.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_mode.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../theme.dart';

class TechDashboardScreen extends ConsumerWidget {
  const TechDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Technician dashboard'), actions: [
        IconButton(
            tooltip: 'Toggle light/dark',
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(mode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined)),
        IconButton(
            onPressed: () => context.go(AppRoutes.notifications),
            icon: Icon(Icons.notifications_outlined)),
        IconButton(
            onPressed: () => context.go(AppRoutes.techProfile),
            icon: Icon(Icons.person_outline))
      ]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) context.go(AppRoutes.techRequests);
          if (i == 2) context.go(AppRoutes.techEarnings);
          if (i == 3) context.go(AppRoutes.techProfile);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.inbox_outlined), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AvailabilityToggle(),
          const SizedBox(height: 12),
          RcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TODAY — 3 JOBS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                        color: RepairColors.tealOn(context))),
                const SizedBox(height: 6),
                Text('09:00 Anesthesia Vent Calibration — SCHEDULED',
                    style: TextStyle(fontSize: 12, color: RepairColors.headingOn(context))),
                Text('13:00 Washer Diagnostics — ACCEPTED',
                    style: TextStyle(fontSize: 12, color: RepairColors.headingOn(context))),
                Text('16:00 HVAC Filter — REQUESTED',
                    style: TextStyle(fontSize: 12, color: RepairColors.mutedOn(context))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE JOB',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                        color: RepairColors.tealOn(context))),
                const SizedBox(height: 6),
                Text('Anesthesia Vent Calibration — IPC-9028-T',
                    style: TextStyle(fontWeight: FontWeight.w700, color: RepairColors.headingOn(context))),
                Text('St. Jude Research Wing • Today 09:00',
                    style: TextStyle(fontSize: 12, color: RepairColors.mutedOn(context))),
                const SizedBox(height: 10),
                RcButton(
                    label: 'Open job',
                    onPressed: () => context.go('${AppRoutes.bookingDetail}/b-demo')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RcCard(
            onTap: () => context.go(AppRoutes.techEarnings),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EARNINGS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                        color: RepairColors.tealOn(context))),
                Text('\$1,284.00',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800, color: RepairColors.headingOn(context))),
                Text('12 completed • 2 pending payout — tap for details',
                    style: TextStyle(fontSize: 12, color: RepairColors.mutedOn(context))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RcButton(
              label: 'Manage availability',
              outline: true,
              onPressed: () => context.go(AppRoutes.techAvailability)),
        ],
      ),
    );
  }
}

class AvailabilityToggle extends StatefulWidget {
  const AvailabilityToggle({super.key});
  @override
  State<AvailabilityToggle> createState() => _AState();
}

class _AState extends State<AvailabilityToggle> {
  bool _on = true;
  @override
  Widget build(BuildContext context) {
    return RcCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Availability',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: RepairColors.headingOn(context))),
                Text(_on ? 'Online — can accept jobs' : 'Offline',
                    style: TextStyle(
                        fontSize: 12, color: RepairColors.mutedOn(context))),
              ],
            ),
          ),
          Switch(value: _on, onChanged: (v) => setState(() => _on = v)),
        ],
      ),
    );
  }
}

class TechRequestsScreen extends ConsumerWidget {
  const TechRequestsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final allowed = user == null ? true : techAcceptAllowed(user);
    final items = [
      ('req-101', 'Washer Diagnostics', 'Customer reports no-spin + leak.', 'REQUESTED'),
      ('req-102', 'HVAC Filter + Calibration', 'Clinic wing B, restricted access.', 'REQUESTED'),
    ];
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Incoming requests',
          fallback: AppRoutes.techDashboard),
      body: Column(
        children: [
          if (!allowed)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RepairColors.copperBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: RepairColors.copper),
              ),
              child: Text(
                  'Verification pending — you can review requests but Accept unlocks after approval.',
                  style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final r = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$2,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: RepairColors.headingOn(context))),
                        Text(r.$3,
                            style: TextStyle(
                                fontSize: 12,
                                color: RepairColors.mutedOn(context))),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                                child: RcButton(
                                    label: allowed
                                        ? 'Accept'
                                        : 'Pending approval',
                                    onPressed: allowed
                                        ? () => context.go(
                                            '${AppRoutes.bookingDetail}/${r.$1}')
                                        : null)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: RcButton(
                                    label: 'Reject',
                                    outline: true,
                                    onPressed: () => ScaffoldMessenger.of(
                                            context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Request declined.'))))),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: () => ScaffoldMessenger.of(
                                      context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Reported. Admin will review.'))),
                              child: Text('Report request',
                                  style: TextStyle(fontSize: 11))),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
