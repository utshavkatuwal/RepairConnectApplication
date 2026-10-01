// ignore_for_file: prefer_const_constructors
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/location_picker.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../services/location/location_service.dart';
import '../../../shared/models/models.dart';
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

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Earnings', fallback: AppRoutes.techDashboard),
      body: FutureBuilder<double>(
        future: ref.watch(walletRepoProvider).balance(),
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
          final balance = snap.data ?? 0;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RcCard(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text('WITHDRAWABLE BALANCE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color:
                                RepairColors.tealOn(context))),
                      Text('NPR ${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: RepairColors.headingOn(
                                context))),
                    Text('Derived from the ledger below',
                        style: TextStyle(
                            fontSize: 12,
                            color: RepairColors.mutedOn(
                                context))),
                    const SizedBox(height: 10),
                    RcButton(
                        label: 'Request withdrawal',
                        onPressed: balance > 0
                            ? () => _withdrawDialog(
                                context, ref)
                            : null),
                  ])),
              const SizedBox(height: 12),
              Text('TRANSACTION HISTORY',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: RepairColors.tealOn(context))),
              const SizedBox(height: 8),
              FutureBuilder<List<Transaction>>(
                future:
                    ref.watch(walletRepoProvider).ledger(),
                builder: (c2, lSnap) {
                  if (lSnap.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final txs = lSnap.data ?? [];
                  if (txs.isEmpty) {
                    return Text('No ledger entries yet.',
                        style: TextStyle(
                            fontSize: 12,
                            color: RepairColors.mutedOn(
                                context)));
                  }
                  return Column(
                    children: [
                      for (final e in txs)
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8),
                          child: RcCard(
                              child: Row(children: [
                            Expanded(
                                child: Text(e.paymentId,
                                    style: TextStyle(
                                        color: RepairColors
                                            .headingOn(
                                                context)))),
                            Text(
                                'NPR ${e.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: RepairColors
                                        .headingOn(context))),
                            const SizedBox(width: 8),
                            Text(e.kind,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: e.amount >= 0
                                        ? RepairColors.tealOn(
                                            context)
                                        : RepairColors.copper)),
                          ])),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _withdrawDialog(
      BuildContext context, WidgetRef ref) async {
    final amount = TextEditingController();
    final method = TextEditingController(text: 'esewa');
    final account = TextEditingController();
    final f = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request withdrawal'),
        content: Form(
          key: f,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                  controller: amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Amount'),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) {
                      return 'Enter a positive amount';
                    }
                    return null;
                  }),
              TextFormField(
                  controller: method,
                  decoration: const InputDecoration(
                      labelText: 'Method (esewa/khalti/bank)'),
                  validator: (v) =>
                      requiredValidator(v, 'Method')),
              TextFormField(
                  controller: account,
                  decoration: const InputDecoration(
                      labelText: 'Account identifier'),
                  validator: (v) => requiredValidator(
                      v, 'Account identifier')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Back')),
          ElevatedButton(
              onPressed: () {
                if (f.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text('Submit')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(walletRepoProvider).withdraw(
          amount: double.parse(amount.text.trim()),
          method: method.text.trim(),
          account: account.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Withdrawal requested. Admin reviews it.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
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
      body: FutureBuilder<Map<String, dynamic>>(
        future:
            ref.watch(catalogRepoProvider).technicianProfile(),
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
          final p = snap.data ?? {};
          final docs = p['documents'];
          final docList =
              docs is List ? docs : const [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RcCard(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text(user?.name ?? 'Technician',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: RepairColors.headingOn(
                                context))),
                    Text('${p['specialty'] ?? 'No specialty set'}',
                        style: TextStyle(
                            color: RepairColors.mutedOn(
                                context))),
                    const SizedBox(height: 6),
                    Text(
                        '★ ${p['rating'] ?? 0} • ${p['jobs_completed'] ?? 0} jobs • ${p['experience_years'] ?? 0} yrs',
                        style: const TextStyle(
                            color: RepairColors.star)),
                    Text(
                        'Verification: ${p['verification_status'] ?? 'unknown'}',
                        style: TextStyle(
                            fontSize: 12,
                            color: RepairColors.tealOn(
                                context))),
                  ])),
              const SizedBox(height: 12),
              RcCard(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text('DOCUMENTS',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: RepairColors.tealOn(
                                context))),
                    const SizedBox(height: 6),
                    if (docList.isEmpty)
                      Text('No documents uploaded yet.',
                          style: TextStyle(
                              fontSize: 12,
                              color: RepairColors.mutedOn(
                                  context))),
                    for (final d in docList)
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 4),
                        child: Text(
                            '${(d as Map)['document_type']} — ${(d)['status']}',
                            style: TextStyle(
                                fontSize: 12,
                                color: RepairColors.headingOn(
                                    context))),
                      ),
                  ])),
              const SizedBox(height: 12),
              RcButton(
                  label: 'Edit availability',
                  outline: true,
                  onPressed: () => context
                      .go(AppRoutes.techAvailability)),
            ],
          );
        },
      ),
    );
  }
}

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});
  @override
  ConsumerState<AvailabilityScreen> createState() => _AvState();
}

class _AvState extends ConsumerState<AvailabilityScreen> {
  bool _on = true;
  bool _loading = true;
  bool _busy = false;
  String? _err;

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
            _on = p['availability_status'] != 'offline';
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
      return Scaffold(
        appBar: const RcBackAppBar(
            title: 'Availability',
            fallback: AppRoutes.techDashboard),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
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
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                  Text('Online status',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: RepairColors.headingOn(
                              context))),
                  Text(
                      _on
                          ? 'Online — visible for new requests'
                          : 'Offline — hidden from matching',
                      style: TextStyle(
                          fontSize: 12,
                          color: RepairColors.mutedOn(
                              context))),
                ])),
            _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2))
                : Switch(
                    value: _on,
                    onChanged: (v) async {
                      setState(() {
                        _busy = true;
                        _err = null;
                      });
                      try {
                        await ref
                            .read(technicianRepoProvider)
                            .setAvailability(
                                v ? 'online' : 'offline');
                        setState(() => _on = v);
                      } catch (e) {
                        setState(() => _err = '$e');
                      } finally {
                        if (mounted) {
                          setState(() => _busy = false);
                        }
                      }
                    }),
          ])),
          if (_err != null) ...[
            const SizedBox(height: 8),
            Text(_err!,
                style: const TextStyle(
                    fontSize: 12, color: RepairColors.red)),
          ],
          const SizedBox(height: 8),
          Text(
              'Service area and working location are part of your registration profile and GPS position.',
              style: TextStyle(
                  fontSize: 12,
                  color: RepairColors.mutedOn(context))),
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
  final _exp = TextEditingController();
  final _radius = TextEditingController(text: '25');
  final _bio = TextEditingController();
  String? _specialtyId;
  LatLng? _pos;
  PlatformFile? _photo;
  final List<PlatformFile> _docs = [];
  String _docType = 'government_id';
  bool _busy = false;
  String? _err;
  String? _done;

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
            FutureBuilder<List<Category>>(
              future:
                  ref.watch(catalogRepoProvider).categories(),
              builder: (ctx, snap) {
                final cats = snap.data ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _specialtyId,
                  decoration: const InputDecoration(
                      labelText: 'SPECIALTY (FROM BACKEND)'),
                  items: [
                    for (final c in cats)
                      DropdownMenuItem(
                          value: c.id, child: Text(c.name)),
                  ],
                  validator: (v) => v == null
                      ? 'Select your specialty'
                      : null,
                  onChanged: (v) => setState(() {
                    _specialtyId = v;
                  }),
                );
              },
            ),
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
                label: 'SERVICE RADIUS (KM)',
                controller: _radius,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1 || n > 500) {
                    return 'Enter 1–500';
                  }
                  return null;
                },
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            RcField(
                label: 'PROFILE BIO',
                controller: _bio,
                maxLines: 3,
                validator: (v) => (v == null || v.trim().length < 20)
                    ? 'Min 20 chars'
                    : null),
            const SizedBox(height: 12),
            LocationPicker(
              onChanged: (pos, _) =>
                  setState(() => _pos = pos),
            ),
            if (_pos == null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('GPS position required.',
                    style: TextStyle(
                        fontSize: 11,
                        color: RepairColors.mutedOn(context))),
              ),
            const SizedBox(height: 12),
            RcCard(
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                  Text('VERIFICATION DOCUMENTS',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color:
                              RepairColors.tealOn(context))),
                  const SizedBox(height: 8),
                  Text('PROFILE PHOTO (REQUIRED)',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: RepairColors.headingOn(
                              context))),
                  const SizedBox(height: 4),
                  if (_photo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                          '${_photo!.name} (${(_photo!.size / 1024).toStringAsFixed(0)} KB)',
                          style: TextStyle(
                              fontSize: 12,
                              color: RepairColors.mutedOn(
                                  context))),
                    ),
                  RcButton(
                      label: _photo == null
                          ? 'Pick profile photo (JPG/PNG)'
                          : 'Change profile photo',
                      outline: true,
                      onPressed: () async {
                        final picked = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: const [
                              'jpg',
                              'jpeg',
                              'png'
                            ],
                            withData: true);
                        if (picked != null &&
                            picked.files.isNotEmpty) {
                          setState(() =>
                              _photo = picked.files.first);
                        }
                      }),
                  const SizedBox(height: 10),
                  Text('CREDENTIAL DOCUMENTS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: RepairColors.headingOn(
                              context))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _docType,
                    decoration: const InputDecoration(
                        labelText: 'DOCUMENT TYPE'),
                    items: const [
                      DropdownMenuItem(
                          value: 'government_id',
                          child: Text('Government ID')),
                      DropdownMenuItem(
                          value: 'professional_certificate',
                          child:
                              Text('Professional certificate')),
                      DropdownMenuItem(
                          value: 'license',
                          child: Text('License')),
                      DropdownMenuItem(
                          value: 'experience_proof',
                          child: Text('Experience proof')),
                      DropdownMenuItem(
                          value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(
                        () => _docType = v ?? _docType),
                  ),
                  const SizedBox(height: 8),
                  for (final d in _docs)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 4),
                      child: Text(
                          '${d.name} (${(d.size / 1024).toStringAsFixed(0)} KB)',
                          style: TextStyle(
                              fontSize: 12,
                              color: RepairColors.headingOn(
                                  context))),
                    ),
                  RcButton(
                      label: 'Pick file (PDF/JPG/PNG, max 10MB)',
                      outline: true,
                      onPressed: () async {
                        final picked = await FilePicker.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: const [
                              'pdf',
                              'jpg',
                              'jpeg',
                              'png'
                            ],
                            withData: true);
                        if (picked != null) {
                          setState(() => _docs.addAll(
                              picked.files));
                        }
                      }),
                ])),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(_err!,
                  style: const TextStyle(
                      fontSize: 12, color: RepairColors.red)),
            ],
            if (_done != null) ...[
              const SizedBox(height: 10),
              Text(_done!,
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          RepairColors.tealOn(context))),
            ],
            const SizedBox(height: 8),
            Text(
                'Verification status becomes pending in the backend. Accept unlocks after admin approval.',
                style: TextStyle(
                    fontSize: 12,
                    color: RepairColors.mutedOn(context))),
            const SizedBox(height: 12),
            RcButton(
                label: 'Submit for verification',
                loading: _busy,
                onPressed: () => _submit()),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_f.currentState!.validate()) return;
    if (_specialtyId == null || _pos == null) {
      setState(() => _err =
          'Specialty and GPS position are required.');
      return;
    }
    if (_photo == null) {
      setState(() =>
          _err = 'Profile photo is required for verification.');
      return;
    }
    if (_docs.isEmpty) {
      setState(() => _err =
          'Upload at least one credential document.');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
      _done = null;
    });
    try {
      final repo = ref.read(technicianRepoProvider);
      await repo.saveProfile(
        specialtyId: _specialtyId!,
        bio: _bio.text.trim(),
        experienceYears: int.parse(_exp.text.trim()),
        serviceRadius: int.parse(_radius.text.trim()),
        latitude: _pos!.lat,
        longitude: _pos!.lng,
      );
      var uploaded = 0;
      await repo.uploadDocument(
          file: _photo!, documentType: 'profile_photo');
      uploaded++;
      for (final d in _docs) {
        await repo.uploadDocument(
            file: d, documentType: _docType);
        uploaded++;
      }
      if (!mounted) return;
      setState(() => _done =
          'Submitted. Status: pending.$uploaded document(s) uploaded. An admin will review.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Verification pending.')));
      }
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
