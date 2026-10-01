// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/auth/role_guards.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_mode.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../shared/models/models.dart';
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
            icon: Icon(Icons.person_outline)),
        IconButton(
            tooltip: 'Log out',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: Icon(Icons.logout_outlined))
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
      body: FutureBuilder<List<Booking>>(
        future: ref.watch(bookingsRepoProvider).myBookings(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return AsyncStateView(
                loading: false,
                failure: snap.error,
                onRetry: () => (context as Element).markNeedsBuild(),
                onLogin: () async {
                  await ref.read(authProvider.notifier).expire();
                  if (context.mounted) context.go(AppRoutes.login);
                },
                child: const SizedBox());
          }
          final jobs = snap.data ?? [];
          final active = jobs.where((j) =>
              j.status != JobStatus.completed &&
              j.status != JobStatus.cancelled &&
              j.status != JobStatus.disputed);
          final current = active.isEmpty ? null : active.first;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const AvailabilityToggle(),
              const SizedBox(height: 12),
              RcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MY JOBS (${jobs.length})',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: RepairColors.tealOn(context))),
                    const SizedBox(height: 6),
                    if (jobs.isEmpty)
                      Text('No jobs yet. New requests appear under Requests once approved.',
                          style: TextStyle(
                              fontSize: 12,
                              color: RepairColors.mutedOn(context))),
                    for (final j in jobs.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('${j.id} — ${j.status}',
                            style: TextStyle(
                                fontSize: 12,
                                color: RepairColors.headingOn(context))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (current != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACTIVE JOB',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: RepairColors.tealOn(context))),
                        const SizedBox(height: 6),
                        Text('Booking ${current.id} — ${current.status}',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: RepairColors.headingOn(context))),
                        const SizedBox(height: 10),
                        RcButton(
                            label: 'Open job',
                            onPressed: () => context.push(
                                '${AppRoutes.bookingDetail}/${current.id}')),
                      ],
                    ),
                  ),
                ),
              RcCard(
                onTap: () => context.go(AppRoutes.techEarnings),
                child: FutureBuilder<double>(
                  future:
                      ref.watch(walletRepoProvider).balance(),
                  builder: (c2, bSnap) {
                    final bal = bSnap.data;
                    return Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('EARNINGS',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color:
                                    RepairColors.tealOn(context))),
                        Text(
                            bal == null
                                ? '…'
                                : 'NPR ${bal.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: RepairColors.headingOn(
                                    context))),
                        Text('Tap for ledger and withdrawals',
                            style: TextStyle(
                                fontSize: 12,
                                color: RepairColors.mutedOn(
                                    context))),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              RcButton(
                  label: 'Manage availability',
                  outline: true,
                  onPressed: () =>
                      context.go(AppRoutes.techAvailability)),
            ],
          );
        },
      ),
    );
  }
}

class AvailabilityToggle extends ConsumerStatefulWidget {
  const AvailabilityToggle({super.key});
  @override
  ConsumerState<AvailabilityToggle> createState() => _AState();
}

class _AState extends ConsumerState<AvailabilityToggle> {
  // Backend states: online (can accept) | busy (active job) | offline.
  String _status = 'offline';
  bool _busy = false;
  bool _loading = true;
  bool get _on => _status == 'online';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final p = await ref
            .read(catalogRepoProvider)
            .technicianProfile();
        if (mounted) {
          setState(() {
            _status = '${p['availability_status'] ?? 'offline'}';
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const RcCard(
          child: Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2))));
    }
    return RcCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Availability',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: RepairColors.headingOn(context))),
                Text(
                    switch (_status) {
                      'online' => 'Online — can accept jobs',
                      'busy' => 'Busy — finish your active job first',
                      _ => 'Offline',
                    },
                    style: TextStyle(
                        fontSize: 12,
                        color: RepairColors.mutedOn(context))),
              ],
            ),
          ),
          _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(strokeWidth: 2))
              : Switch(
                  value: _on,
                  onChanged: (v) async {
                    final messenger =
                        ScaffoldMessenger.of(context);
                    setState(() => _busy = true);
                    try {
                      await ref
                          .read(technicianRepoProvider)
                          .setAvailability(
                              v ? 'online' : 'offline');
                      setState(() =>
                          _status = v ? 'online' : 'offline');
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(
                          content: Text(e.toString())));
                    } finally {
                      if (mounted) {
                        setState(() => _busy = false);
                      }
                    }
                  }),
        ],
      ),
    );
  }
}

class TechRequestsScreen extends ConsumerStatefulWidget {
  const TechRequestsScreen({super.key});
  @override
  ConsumerState<TechRequestsScreen> createState() =>
      _RequestsState();
}

class _RequestsState extends ConsumerState<TechRequestsScreen> {
  String? _busyId;
  String? _err;

  /// Backend stores UTC; show the technician's local wall-clock time.
  String _fmtLocal(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final l = dt.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _accept(ServiceRequest r) async {
    setState(() {
      _busyId = r.id;
      _err = null;
    });
    try {
      final job =
          await ref.read(bookingsRepoProvider).acceptRequest(r.id);
      if (!mounted) return;
      context.push('${AppRoutes.bookingDetail}/${job.id}');
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final allowed = user == null ? true : techAcceptAllowed(user);
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
                  'Verification ${user.techStatus} — Accept unlocks after approval. Your status comes from the backend.',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white)),
            ),
          Expanded(
            child: FutureBuilder<List<ServiceRequest>>(
              future:
                  ref.watch(catalogRepoProvider).openRequests(),
              builder: (ctx, snap) {
                if (snap.connectionState ==
                    ConnectionState.waiting) {
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
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const AsyncStateView(
                      loading: false,
                      empty: true,
                      emptyText:
                          'No open requests match your specialty and area right now.',
                      child: SizedBox());
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final r = items[i];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: 10),
                      child: RcCard(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                                r.title ?? 'Service request',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: RepairColors.headingOn(
                                        context))),
                            Text(
                                '${r.description}${r.km == null ? '' : ' ${r.km!.toStringAsFixed(1)} km'}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: RepairColors.mutedOn(
                                        context))),
                            if (r.preferredAt != null)
                              Text(
                                  'Scheduled: ${_fmtLocal(r.preferredAt!)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: RepairColors.tealOn(
                                          context))),
                            const SizedBox(height: 10),
                            if (_err != null && _busyId == null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: Text(_err!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: RepairColors.red)),
                              ),
                            Row(
                              children: [
                                Expanded(
                                    child: RcButton(
                                        label: allowed
                                            ? 'Accept'
                                            : 'Pending approval',
                                        loading:
                                            _busyId == r.id,
                                        onPressed: allowed &&
                                                _busyId == null
                                            ? () => _accept(r)
                                            : null)),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  onPressed: () =>
                                      ScaffoldMessenger.of(
                                              context)
                                          .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Reported. Admin will review.'))),
                                  child: Text('Report request',
                                      style: TextStyle(
                                          fontSize: 11))),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
