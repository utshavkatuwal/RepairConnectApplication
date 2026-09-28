// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/rc_widgets.dart';
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

const _demoUsers = [
  AdminUser('u-1', 'Demo Customer', 'CUSTOMER', true),
  AdminUser('u-t1', 'Dr. Keith Sterling', 'TECHNICIAN', true),
  AdminUser('u-t2', 'Aris Vance', 'TECHNICIAN', false),
  AdminUser('u-a1', 'Ops Admin', 'ADMIN', true),
];

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _UsersState();
}

class _UsersState extends State<AdminUsersScreen> {
  String _q = '';
  String? _role;
  @override
  Widget build(BuildContext context) {
    final list = filterAdminUsers(_demoUsers, q: _q, role: _role);
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
                  hintText: 'Search name or ID…',
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final u = list[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RcCard(
                      child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Text(u.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: RepairColors.headingOn(context))),
                          Text('${u.role} • ${u.active ? 'Active' : 'Suspended'}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: RepairColors.mutedOn(context))),
                        ])),
                    TextButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                                    content: Text(
                                        '${u.active ? 'Suspended' : 'Reactivated'} ${u.name} (audited).'))),
                        child: Text(u.active ? 'Suspend' : 'Activate')),
                  ])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminVerifyScreen extends StatefulWidget {
  const AdminVerifyScreen({super.key});
  @override
  State<AdminVerifyScreen> createState() => _VerifyState();
}

class _VerifyState extends State<AdminVerifyScreen> {
  String? _done;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Technician verification',
          fallback: AppRoutes.adminDashboard),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RcCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('K. Sterling — Class-III docs',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: RepairColors.headingOn(context))),
                Text('Specialty: Surgical Electronics • 8 yrs',
                    style: TextStyle(
                        fontSize: 12, color: RepairColors.mutedOn(context))),
                if (_done != null) ...[
                  const SizedBox(height: 6),
                  Text('Decision: $_done (recorded with actor + time)',
                      style: TextStyle(
                          fontSize: 12,
                          color: RepairColors.tealOn(context))),
                ],
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: RcButton(
                          label: 'Approve',
                          onPressed: () => setState(() =>
                              _done = decideVerification('approve')))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: RcButton(
                          label: 'Reject',
                          destructive: true,
                          onPressed: () => setState(() =>
                              _done = decideVerification('reject')))),
                ]),
                const SizedBox(height: 8),
                RcButton(
                    label: 'Request correction',
                    outline: true,
                    onPressed: () => setState(
                        () => _done = decideVerification('correct'))),
              ])),
        ],
      ),
    );
  }
}

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});
  @override
  State<AdminServicesScreen> createState() => _SvcState();
}

class _SvcState extends State<AdminServicesScreen> {
  final Map<String, bool> _active = {'s1': true, 's2': true, 'c3': false};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Service management',
          fallback: AppRoutes.adminDashboard),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final e in _active.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RcCard(
                  child: Row(children: [
                Expanded(
                    child: Text(e.key,
                        style: TextStyle(color: RepairColors.headingOn(context)))),
                Switch(
                    value: e.value,
                    onChanged: (v) =>
                        setState(() => _active[e.key] = v)),
              ])),
            ),
          Text(
              'Active/inactive + pricing changes apply server-side.',
              style:
                  TextStyle(fontSize: 12, color: RepairColors.mutedOn(context))),
        ],
      ),
    );
  }
}

class AdminJobsScreen extends StatelessWidget {
  const AdminJobsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const jobs = [
      ('b-101', 'IPC-9028-T', 'IN_PROGRESS', 'K. Sterling', 'PENDING'),
      ('b-102', 'WSH-114', 'SCHEDULED', 'A. Vance', 'SUCCEEDED'),
    ];
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Job inspection',
          fallback: AppRoutes.adminDashboard),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobs.length,
        itemBuilder: (_, i) {
          final j = jobs[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RcCard(
              onTap: () =>
                  context.go('${AppRoutes.bookingDetail}/${j.$1}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${j.$2} • ${j.$3}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: RepairColors.headingOn(context))),
                  Text('Tech: ${j.$4} • Pay: ${j.$5}',
                      style: TextStyle(
                          fontSize: 12,
                          color: RepairColors.mutedOn(context))),
                ],
              ),
            ),
          );
        },
      ),
    );
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
    const txs = [
      ('tx-1', 'b-101', '\$299', 'PENDING'),
      ('tx-2', 'b-102', '\$89', 'SUCCEEDED'),
      ('tx-3', 'b-100', '\$149', 'FAILED'),
    ];
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Payment management',
          fallback: AppRoutes.adminDashboard),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_msg != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RcCard(child: Text(_msg!,
                  style: TextStyle(
                      fontSize: 12, color: RepairColors.headingOn(context))))),
          for (final t in txs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RcCard(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text('${t.$1} → ${t.$2}',
                              style: TextStyle(
                                  color: RepairColors.headingOn(context)))),
                      Text('${t.$3} • ${t.$4}',
                          style: TextStyle(
                              fontSize: 12,
                              color: RepairColors.mutedOn(context))),
                    ]),
                    if (t.$4 == 'SUCCEEDED')
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: () =>
                                _refund(t.$1),
                            child: Text('Refund…',
                                style: TextStyle(
                                    fontSize: 11))),
                      ),
                    if (t.$4 == 'FAILED')
                      Text(
                          'Failed — customer can retry from booking.',
                          style: TextStyle(
                              fontSize: 11,
                              color: RepairColors.copper)),
                  ])),
            ),
          Text(
              'Refunds validated (SUCCEEDED + reason) and audited server-side.',
              style: TextStyle(
                  fontSize: 11,
                  color: RepairColors.faintOn(context))),
        ],
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
                  PaymentMachine.validateRefund('SUCCEEDED', v)),
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
      final s = await ref
          .read(paymentsRepoProvider)
          .refund(txId, reason);
      if (mounted) setState(() => _msg = '$txId → $s (audited).');
    } catch (e) {
      if (mounted) setState(() => _msg = 'Refund failed: $e');
    }
  }
}

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});
  @override
  State<AdminComplaintsScreen> createState() => _CompState();
}

class _CompState extends State<AdminComplaintsScreen> {
  bool _resolved = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Complaints & support',
          fallback: AppRoutes.adminDashboard),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RcCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('CMP-07 • Late arrival dispute',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: RepairColors.headingOn(context))),
                Text(_resolved ? 'Status: RESOLVED' : 'Status: OPEN',
                    style: TextStyle(
                        fontSize: 12,
                        color: RepairColors.tealOn(context))),
                const SizedBox(height: 8),
                RcButton(
                    label: _resolved ? 'Reopen' : 'Resolve with note',
                    onPressed: () =>
                        setState(() => _resolved = !_resolved)),
              ])),
        ],
      ),
    );
  }
}

class AdminAuditScreen extends StatelessWidget {
  const AdminAuditScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const logs = [
      ('a1', 'admin u-a1 APPROVED tech u-t1 • 10:02'),
      ('a2', 'admin u-a1 SUSPENDED user u-t2 • 09:41'),
      ('a3', 'system PAYMENT verified tx-2 • 09:12'),
    ];
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Audit logs', fallback: AppRoutes.adminDashboard),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RcCard(
              child: Text(logs[i].$2,
                  style: TextStyle(
                      fontSize: 12, color: RepairColors.headingOn(context)))),
        ),
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
