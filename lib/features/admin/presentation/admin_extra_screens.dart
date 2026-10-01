// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../shared/models/models.dart';
import '../../payments/domain/payment_machine.dart';
import '../../../theme.dart';

/// Pure admin helpers (§8): user search/filter, verification decisions.
/// Server authorizes + audits; UI mirrors to prevent confusion.

class AdminUser {
  final String id;
  final String name;
  final String role;
  final bool active;
  const AdminUser(this.id, this.name, this.role, this.active);
}

List<AdminUser> filterAdminUsers(List<AdminUser> all,
    {String? q, String? role, bool? activeOnly}) {
  final query = (q ?? '').trim().toLowerCase();
  return all.where((u) {
    if (role != null && u.role != role) return false;
    if (activeOnly == true && !u.active) return false;
    if (query.isEmpty) return true;
    return u.name.toLowerCase().contains(query) ||
        u.id.toLowerCase().contains(query);
  }).toList();
}

/// Verification decision is recorded server-side with actor + timestamp.
String decideVerification(String action) {
  switch (action) {
    case 'approve':
      return 'APPROVED';
    case 'reject':
      return 'REJECTED';
    default:
      return 'CORRECTION';
  }
}

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _UsersState();
}

class _UsersState extends ConsumerState<AdminUsersScreen> {
  String _q = '';
  String? _role;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'User management',
          fallback: AppRoutes.adminDashboard),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(
                  hintText: 'Search name or email…',
                  prefixIcon: Icon(Icons.search, size: 18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: _role,
              decoration:
                  const InputDecoration(labelText: 'ROLE FILTER'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All roles')),
                DropdownMenuItem(
                    value: 'CUSTOMER', child: Text('Customers')),
                DropdownMenuItem(
                    value: 'TECHNICIAN', child: Text('Technicians')),
                DropdownMenuItem(value: 'ADMIN', child: Text('Admins')),
              ],
              onChanged: (v) => setState(() => _role = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<User>>(
              future: ref
                  .watch(adminRepoProvider)
                  .users(q: _q.isEmpty ? null : _q, role: _role),
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
                      onRetry: () => setState(() {}),
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
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const AsyncStateView(
                      loading: false,
                      empty: true,
                      emptyText: 'No users match.',
                      child: SizedBox());
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final u = list[i];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: 8),
                      child: RcCard(
                          child: Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                              Text(u.name,
                                  style: TextStyle(
                                      fontWeight:
                                          FontWeight.w700,
                                      color: RepairColors.headingOn(
                                          context))),
                              Text('${u.role} • ${u.email}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: RepairColors
                                          .mutedOn(context))),
                            ])),
                        TextButton(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(adminRepoProvider)
                                    .suspend(u.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Account status toggled (audited).')));
                                  setState(() {});
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(
                                          context)
                                      .showSnackBar(SnackBar(
                                          content:
                                              Text('$e')));
                                }
                              }
                            },
                            child: Text('Suspend')),
                      ])),
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

class AdminVerifyScreen extends ConsumerStatefulWidget {
  const AdminVerifyScreen({super.key});
  @override
  ConsumerState<AdminVerifyScreen> createState() => _VerifyState();
}

class _VerifyState extends ConsumerState<AdminVerifyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Technician verification',
          fallback: AppRoutes.adminDashboard),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.watch(adminRepoProvider).verificationQueue(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return AsyncStateView(
                loading: false,
                failure: snap.error,
                onRetry: () => setState(() {}),
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
                emptyText: 'Verification queue is clear.',
                child: SizedBox());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final p = items[i];
              final user = p['user'];
              final spec = p['specialty'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RcCard(
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                      Text(
                          '${user is Map ? user['name'] ?? 'Technician' : 'Technician'} — ${spec is Map ? spec['name'] ?? '' : ''}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: RepairColors.headingOn(
                                  context))),
                      Text(
                          'Exp: ${p['experience_years'] ?? '?'} yrs • ${p['bio'] ?? ''}',
                          style: TextStyle(
                              fontSize: 12,
                              color: RepairColors.mutedOn(
                                  context))),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: RcButton(
                                label: 'Approve',
                                onPressed: () =>
                                    _decide('${p['id']}', 'approve'))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: RcButton(
                                label: 'Reject',
                                destructive: true,
                                onPressed: () =>
                                    _decide('${p['id']}', 'reject'))),
                      ]),
                      const SizedBox(height: 8),
                      RcButton(
                          label: 'Request correction',
                          outline: true,
                          onPressed: () => _decide(
                              '${p['id']}',
                              'resubmit',
                              needsReason: true)),
                    ])),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _decide(String id, String action,
      {bool needsReason = false}) async {
    String? reason;
    if (action != 'approve' || needsReason) {
      reason = await _askReason(action);
      if (reason == null) return;
    }
    try {
      await ref
          .read(adminRepoProvider)
          .verify(id, action, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('${decideVerification(action)} recorded (audited).')));
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<String?> _askReason(String action) async {
    final c = TextEditingController();
    final f = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action == 'approve'
            ? 'Approve'
            : 'Reason required'),
        content: Form(
          key: f,
          child: TextFormField(
              controller: c,
              maxLines: 2,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: 'Reason (min 5 chars)'),
              validator: (v) =>
                  (v == null || v.trim().length < 5)
                      ? 'Reason required (min 5)'
                      : null),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Back')),
          ElevatedButton(
              onPressed: () {
                if (!f.currentState!.validate()) return;
                Navigator.pop(ctx, c.text.trim());
              },
              child: Text('Confirm')),
        ],
      ),
    );
  }
}

class AdminServicesScreen extends ConsumerStatefulWidget {
  const AdminServicesScreen({super.key});
  @override
  ConsumerState<AdminServicesScreen> createState() => _SvcState();
}

class _SvcState extends ConsumerState<AdminServicesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Service management',
          fallback: AppRoutes.adminDashboard),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future:
            ref.watch(adminRepoProvider).specialties(),
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
                onRetry: () => setState(() {}),
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
                emptyText: 'No specialties yet.',
                child: SizedBox());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final e in items)
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8),
                  child: RcCard(
                      child: Row(children: [
                    Expanded(
                        child: Text('${e['name']}',
                            style: TextStyle(
                                color: RepairColors.headingOn(
                                    context)))),
                    Switch(
                        value: e['status'] != 'inactive',
                        onChanged: (v) async {
                          try {
                            await ref
                                .read(adminRepoProvider)
                                .setSpecialtyActive(
                                    '${e['id']}', v);
                            setState(() {});
                          } catch (err) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content:
                                          Text('$err')));
                            }
                          }
                        }),
                  ])),
                ),
              Text(
                  'Active/inactive applies server-side immediately.',
                  style: TextStyle(
                      fontSize: 12,
                      color: RepairColors.mutedOn(context))),
            ],
          );
        },
      ),
    );
  }
}

class AdminJobsScreen extends ConsumerWidget {
  const AdminJobsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Job inspection',
          fallback: AppRoutes.adminDashboard),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.watch(adminRepoProvider).jobs(),
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
                child: const SizedBox());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const AsyncStateView(
                loading: false,
                empty: true,
                emptyText: 'No jobs yet.',
                child: SizedBox());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final j = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RcCard(
                  onTap: () => context.go(
                      '${AppRoutes.bookingDetail}/${j['id']}'),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('Job ${j['id']} • ${j['status']}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: RepairColors.headingOn(
                                  context))),
                      Text(
                          'Customer: ${_nested(j['customer'], 'name')} • Tech: ${_nested(j['technician'], 'name')}',
                          style: TextStyle(
                              fontSize: 12,
                              color: RepairColors.mutedOn(
                                  context))),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _nested(Object? v, String key) {
    if (v is Map && v[key] != null) return '${v[key]}';
    return '—';
  }
}

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});
  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _PayState();
}

class _PayState
    extends ConsumerState<AdminPaymentsScreen> {
  String? _msg;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Payment management',
          fallback: AppRoutes.adminDashboard),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.watch(adminRepoProvider).payments(),
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
                onRetry: () => setState(() {}),
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
          final txs = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_msg != null)
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8),
                  child: RcCard(
                      child: Text(_msg!,
                          style: TextStyle(
                              fontSize: 12,
                              color: RepairColors.headingOn(
                                  context)))),
                ),
              if (txs.isEmpty)
                Text('No transactions yet.',
                    style: TextStyle(
                        fontSize: 12,
                        color: RepairColors.mutedOn(context))),
              for (final t in txs)
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8),
                  child: RcCard(
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Expanded(
                              child: Text(
                                  'tx ${t['id']} → booking ${t['job_id']}',
                                  style: TextStyle(
                                      color: RepairColors
                                          .headingOn(
                                              context)))),
                          Text(
                              '${t['amount']} • ${t['status']}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: RepairColors.mutedOn(
                                      context))),
                        ]),
                        if ('${t['status']}' ==
                            'successful')
                          Align(
                            alignment:
                                Alignment.centerRight,
                            child: TextButton(
                                onPressed: () =>
                                    _refund('${t['id']}'),
                                child: Text('Refund…',
                                    style: TextStyle(
                                        fontSize: 11))),
                          ),
                        if ('${t['status']}' == 'failed')
                          Text(
                              'Failed — customer can retry from booking.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      RepairColors.copper)),
                      ])),
                ),
              Text(
                  'Refunds validated (SUCCEEDED + reason) and audited server-side.',
                  style: TextStyle(
                      fontSize: 11,
                      color: RepairColors.faintOn(context))),
            ],
          );
        },
      ),
    );
  }

  Future<void> _refund(String txId) async {
    final c = TextEditingController();
    final f = GlobalKey<FormState>();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Refund payment'),
        content: Form(
          key: f,
          child: TextFormField(
              controller: c,
              maxLines: 2,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: 'Reason (min 5 chars)'),
              validator: (v) =>
                  PaymentMachine.validateRefund(
                      'successful', v)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Back')),
          ElevatedButton(
              onPressed: () {
                if (!f.currentState!.validate()) return;
                Navigator.pop(ctx, c.text.trim());
              },
              child: Text('Refund')),
        ],
      ),
    );
    if (reason == null) return;
    try {
      // Refund goes through the payments repository so the ledger
      // reversal and audit happen server-side.
      await ref.read(paymentsRepoProvider).refund(txId, reason);
      if (mounted) {
        setState(() => _msg = '$txId refund submitted (audited).');
      }
    } catch (e) {
      if (mounted) setState(() => _msg = 'Refund failed: $e');
    }
  }
}

class AdminComplaintsScreen extends ConsumerStatefulWidget {
  const AdminComplaintsScreen({super.key});
  @override
  ConsumerState<AdminComplaintsScreen> createState() =>
      _CompState();
}

class _CompState extends ConsumerState<AdminComplaintsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Complaints & support',
          fallback: AppRoutes.adminDashboard),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.watch(adminRepoProvider).complaints(),
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
                onRetry: () => setState(() {}),
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
                emptyText: 'No complaints filed.',
                child: SizedBox());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final c = items[i];
              final resolved = '${c['status']}' == 'resolved';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RcCard(
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                      Text('${c['body'] ?? ''}',
                          style: TextStyle(
                              color: RepairColors.headingOn(
                                  context))),
                      Text(
                          'Status: ${c['status']}',
                          style: TextStyle(
                              fontSize: 12,
                              color: RepairColors.tealOn(
                                  context))),
                      if (!resolved) ...[
                        const SizedBox(height: 8),
                        RcButton(
                            label: 'Resolve with note',
                            outline: true,
                            onPressed: () =>
                                _resolve('${c['id']}')),
                      ],
                    ])),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _resolve(String id) async {
    final c = TextEditingController();
    final f = GlobalKey<FormState>();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resolve complaint'),
        content: Form(
          key: f,
          child: TextFormField(
              controller: c,
              maxLines: 2,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: 'Resolution (min 5 chars)'),
              validator: (v) =>
                  (v == null || v.trim().length < 5)
                      ? 'Resolution required (min 5)'
                      : null),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Back')),
          ElevatedButton(
              onPressed: () {
                if (!f.currentState!.validate()) return;
                Navigator.pop(ctx, c.text.trim());
              },
              child: Text('Resolve')),
        ],
      ),
    );
    if (note == null) return;
    try {
      await ref.read(adminRepoProvider).resolveComplaint(id, note);
      if (!mounted) return;
      setState(() {});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Complaint resolved (audited).')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Audit logs',
          fallback: AppRoutes.adminDashboard),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.watch(adminRepoProvider).audit(),
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
          final logs = snap.data ?? [];
          if (logs.isEmpty) {
            return const AsyncStateView(
                loading: false,
                empty: true,
                emptyText: 'No admin actions recorded yet.',
                child: SizedBox());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (_, i) {
              final l = logs[i];
              final actor = l['actor'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RcCard(
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                      Text('${l['action']}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: RepairColors.headingOn(
                                  context))),
                      Text(
                          'by ${actor is Map ? actor['name'] ?? '?' : '?'} • ${l['created_at'] ?? ''}',
                          style: TextStyle(
                              fontSize: 11,
                              color: RepairColors.mutedOn(
                                  context))),
                    ])),
              );
            },
          );
        },
      ),
    );
  }
}

/// Review moderation lives on booking reviews; admin uses
/// booking detail + complaints flow (no separate fabricated queue).
class AdminReviewsNote extends StatelessWidget {
  const AdminReviewsNote({super.key});
  @override
  Widget build(BuildContext context) {
    return RcCard(
        child: Text(
            'Reviews moderated per policy: flag → hide pending review → audit.',
            style: TextStyle(
                fontSize: 12,
                color: RepairColors.mutedOn(context))));
  }
}

/// Withdrawal requests: technician asked (amount + platform + mobile);
/// admin initiates the payout, marks it paid, or rejects with a reason.
class AdminWithdrawalsScreen extends ConsumerStatefulWidget {
  const AdminWithdrawalsScreen({super.key});
  @override
  ConsumerState<AdminWithdrawalsScreen> createState() =>
      _WState();
}

class _WState extends ConsumerState<AdminWithdrawalsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Withdrawals',
          fallback: AppRoutes.adminDashboard),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.watch(adminRepoProvider).withdrawals(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return AsyncStateView(
                loading: false,
                failure: snap.error,
                onRetry: () => setState(() {}),
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
                emptyText: 'No withdrawal requests.',
                child: SizedBox());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final w = items[i];
              final status = '${w['status'] ?? ''}';
              final tech = w['technician'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RcCard(
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                      Text(
                          'NPR ${w['amount']} • ${w['method'] ?? ''}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: RepairColors.headingOn(
                                  context))),
                      Text(
                          'To: ${w['account_identifier'] ?? ''} • ${tech is Map ? tech['name'] ?? '' : ''}',
                          style: TextStyle(
                              fontSize: 12,
                              color: RepairColors.mutedOn(
                                  context))),
                      Text('Status: ${status.toUpperCase()}',
                          style: TextStyle(
                              fontSize: 11,
                              color: RepairColors.tealOn(
                                  context))),
                      const SizedBox(height: 10),
                      if (status == 'pending')
                        Row(children: [
                          Expanded(
                              child: RcButton(
                                  label: 'Initiate payout',
                                  onPressed: () => _decide(
                                      '${w['id']}', 'processing'))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: RcButton(
                                  label: 'Reject',
                                  destructive: true,
                                  onPressed: () => _decide(
                                      '${w['id']}',
                                      'rejected',
                                      needsReason: true))),
                        ]),
                      if (status == 'processing')
                        Row(children: [
                          Expanded(
                              child: RcButton(
                                  label: 'Mark as paid',
                                  onPressed: () => _decide(
                                      '${w['id']}', 'paid'))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: RcButton(
                                  label: 'Reject',
                                  destructive: true,
                                  onPressed: () => _decide(
                                      '${w['id']}',
                                      'rejected',
                                      needsReason: true))),
                        ]),
                      if (status == 'paid' &&
                          w['transaction_reference'] != null)
                        Text(
                            'Ref: ${w['transaction_reference']}',
                            style: TextStyle(
                                fontSize: 11,
                                color: RepairColors.mutedOn(
                                    context))),
                    ])),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _decide(String id, String decision,
      {bool needsReason = false}) async {
    String? note;
    if (needsReason) {
      note = await _askReason();
      if (note == null) return;
    } else if (decision == 'paid') {
      note = await _askReference();
      if (note == null) return;
    }
    try {
      await ref
          .read(adminRepoProvider)
          .decideWithdrawal(id, decision, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Withdrawal $decision (audited).')));
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<String?> _askReference() async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payout reference'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Transaction reference / receipt'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back')),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, c.text.trim().isEmpty ? 'manual' : c.text.trim()),
              child: const Text('Confirm paid')),
        ],
      ),
    );
  }

  Future<String?> _askReason() async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejection reason'),
        content: TextField(
          controller: c,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Reason (min 5 chars)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back')),
          ElevatedButton(
              onPressed: () => Navigator.pop(
                  ctx, c.text.trim().length >= 5 ? c.text.trim() : null),
              child: const Text('Reject')),
        ],
      ),
    );
  }
}
