// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../theme.dart';

/// Pure earnings math (§7): completed vs pending vs withdrawable.
class EarningEntry {
  final String id;
  final double amount;
  final bool paid;
  const EarningEntry(this.id, this.amount, this.paid);
}

class EarningsSummary {
  final double current;
  final double pending;
  final int completed;
  const EarningsSummary(
      {required this.current, required this.pending, required this.completed});
}

EarningsSummary summarizeEarnings(List<EarningEntry> entries) {
  double cur = 0, pend = 0;
  var done = 0;
  for (final e in entries) {
    if (e.paid) {
      cur += e.amount;
      done++;
    } else {
      pend += e.amount;
    }
  }
  return EarningsSummary(current: cur, pending: pend, completed: done);
}

const _demoEarnings = [
  EarningEntry('b-101', 299, true),
  EarningEntry('b-102', 89, true),
  EarningEntry('b-103', 149, false),
  EarningEntry('b-104', 210, false),
];

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = summarizeEarnings(_demoEarnings);
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Earnings', fallback: AppRoutes.techDashboard),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RcCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('WITHDRAWABLE BALANCE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: RepairColors.tealOn(context))),
                Text('\$${s.current.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: RepairColors.headingOn(context))),
                Text(
                    '${s.completed} completed • \$${s.pending.toStringAsFixed(2)} pending payout',
                    style: TextStyle(
                        fontSize: 12, color: RepairColors.mutedOn(context))),
                const SizedBox(height: 10),
                RcButton(
                    label: 'Withdraw',
                    onPressed: s.current > 0 ? () {} : null),
              ])),
          const SizedBox(height: 12),
          Text('TRANSACTION HISTORY',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: RepairColors.tealOn(context))),
          const SizedBox(height: 8),
          for (final e in _demoEarnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RcCard(
                  child: Row(children: [
                Expanded(
                    child: Text(e.id,
                        style: TextStyle(color: RepairColors.headingOn(context)))),
                Text('\$${e.amount.toStringAsFixed(0)}',
                    style:
                        TextStyle(color: RepairColors.headingOn(context))),
                const SizedBox(width: 8),
                Text(e.paid ? 'PAID' : 'PENDING',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: e.paid
                            ? RepairColors.tealOn(context)
                            : RepairColors.copper)),
              ])),
            ),
        ],
      ),
    );
  }
}

class TechProfileScreen extends ConsumerWidget {
  const TechProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Technician profile',
          fallback: AppRoutes.techDashboard),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RcCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(user?.name ?? 'Dr. Keith Sterling',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: RepairColors.headingOn(context))),
                Text('Surgical Electronics Specialist',
                    style: TextStyle(color: RepairColors.mutedOn(context))),
                const SizedBox(height: 6),
                Text('★ 4.95 • 142 jobs • 8 yrs experience',
                    style:
                        TextStyle(color: RepairColors.star)),
                Text(
                    'Verification: ${user?.techStatus ?? 'PENDING'}',
                    style: TextStyle(
                        fontSize: 12,
                        color: RepairColors.tealOn(context))),
              ])),
          const SizedBox(height: 12),
          RcCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('SERVICES & AREA',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: RepairColors.tealOn(context))),
                SizedBox(height: 6),
                Text(
                    '• Anesthesia Vent Calibration\n• Washer Diagnostics\n• HVAC Filter + Calibration',
                    style:
                        TextStyle(fontSize: 12, color: RepairColors.headingOn(context))),
                SizedBox(height: 6),
                Text('St. Jude Research Wing + 25km',
                    style: TextStyle(
                        fontSize: 12, color: RepairColors.mutedOn(context))),
              ])),
          const SizedBox(height: 12),
          RcCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('RECENT REVIEWS',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: RepairColors.tealOn(context))),
                SizedBox(height: 6),
                Text(
                    '★★★★★ "Surgical workflow, arrived in 45 min." — Dr. Aris Vance',
                    style:
                        TextStyle(fontSize: 12, color: RepairColors.headingOn(context))),
              ])),
          const SizedBox(height: 12),
          RcButton(
              label: 'Edit availability',
              outline: true,
              onPressed: () =>
                  context.go(AppRoutes.techAvailability)),
        ],
      ),
    );
  }
}

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});
  @override
  State<AvailabilityScreen> createState() => _AvState();
}

class _AvState extends State<AvailabilityScreen> {
  bool _on = true;
  final _area = TextEditingController(text: 'St. Jude Research Wing + 25km');
  final Map<String, bool> _days = {
    'Mon': true, 'Tue': true, 'Wed': true, 'Thu': true, 'Fri': true,
    'Sat': false, 'Sun': false,
  };

  /// Pure validation for working-hours config.
  static String? validateAvailability(
      Map<String, bool> days, String area) {
    if (area.trim().isEmpty) return 'Service area required';
    if (!days.values.any((v) => v)) {
      return 'Select at least one working day';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final err = validateAvailability(_days, _area.text);
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Availability',
          fallback: AppRoutes.techDashboard),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RcCard(
              child: Row(children: [
            Expanded(
                child: Text('Online status',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: RepairColors.headingOn(context)))),
            Switch(
                value: _on,
                onChanged: (v) => setState(() => _on = v)),
          ])),
          const SizedBox(height: 12),
          RcCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WORKING DAYS',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: RepairColors.tealOn(context))),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final d in _days.keys)
                          FilterChip(
                              label: Text(d),
                              selected: _days[d]!,
                              onSelected: (v) =>
                                  setState(() => _days[d] = v)),
                      ],
                    ),
                  ])),
          const SizedBox(height: 12),
          RcField(
              label: 'SERVICE AREA',
              controller: _area,
              validator: (v) => requiredValidator(v, 'Service area')),
          if (err != null) ...[
            const SizedBox(height: 8),
            Text(err,
                style: TextStyle(
                    fontSize: 12, color: RepairColors.copper)),
          ],
          const SizedBox(height: 12),
          RcButton(
              label: 'Save availability',
              onPressed: err == null
                  ? () => ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                          content: Text('Availability saved.')))
                  : null),
        ],
      ),
    );
  }
}

class TechRegisterScreen extends ConsumerStatefulWidget {
  const TechRegisterScreen({super.key});
  @override
  ConsumerState<TechRegisterScreen> createState() => _RegState();
}

class _RegState extends ConsumerState<TechRegisterScreen> {
  final _f = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _specialty = TextEditingController();
  final _exp = TextEditingController();
  final _area = TextEditingController();
  final _bio = TextEditingController();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Technician registration',
          fallback: AppRoutes.landing),
      body: Form(
        key: _f,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            RcField(
                label: 'FULL NAME',
                controller: _name,
                validator: (v) => requiredValidator(v, 'Name')),
            const SizedBox(height: 12),
            RcField(
                label: 'PHONE',
                controller: _phone,
                validator: phoneValidator,
                keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            RcField(
                label: 'SPECIALTY',
                controller: _specialty,
                validator: (v) =>
                    requiredValidator(v, 'Specialty')),
            const SizedBox(height: 12),
            RcField(
                label: 'EXPERIENCE (YEARS)',
                controller: _exp,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Experience required';
                  }
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0 || n > 60) {
                    return 'Enter 0–60';
                  }
                  return null;
                },
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            RcField(
                label: 'SERVICE AREA',
                controller: _area,
                validator: (v) =>
                    requiredValidator(v, 'Service area')),
            const SizedBox(height: 12),
            RcField(
                label: 'PROFILE BIO',
                controller: _bio,
                maxLines: 3,
                validator: (v) => (v == null || v.trim().length < 20)
                    ? 'Min 20 chars'
                    : null),
            const SizedBox(height: 8),
            Text(
                'Verification review follows. Accept unlocks after APPROVED. Documents upload where required by backend.',
                style:
                    TextStyle(fontSize: 12, color: RepairColors.mutedOn(context))),
            const SizedBox(height: 12),
            RcButton(
                label: 'Submit for verification',
                loading: _busy,
                onPressed: () async {
                  if (!_f.currentState!.validate()) return;
                  setState(() => _busy = true);
                  await Future.delayed(
                      const Duration(milliseconds: 400));
                  if (!context.mounted) return;
                  setState(() => _busy = false);
                  context.go(AppRoutes.techDashboard);
                }),
          ],
        ),
      ),
    );
  }
}
