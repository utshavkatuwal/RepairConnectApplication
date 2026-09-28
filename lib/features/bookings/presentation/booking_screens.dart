// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/auth/role_guards.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../services/notifications/push_service.dart';
import '../../../shared/models/models.dart';
import '../../../theme.dart';
import '../../payments/domain/payment_machine.dart';
import '../../reviews/data/reviews_repo.dart';
import '../domain/job_machine.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const BookingDetailScreen({super.key, required this.id});
  @override
  ConsumerState<BookingDetailScreen> createState() => _BState();
}

class _BState extends ConsumerState<BookingDetailScreen> {
  String _status = JobStatus.accepted;
  String? _payState;
  bool _busy = false;
  final List<StatusEvent> _history = [
    StatusEvent(
        from: JobStatus.requested,
        to: JobStatus.accepted,
        actor: AppRoles.technician,
        at: DateTime.now().subtract(const Duration(hours: 2))),
  ];

  Future<void> _move(String to) async {
    final role =
        ref.read(authProvider).valueOrNull?.role ?? AppRoles.customer;
    final messenger = ScaffoldMessenger.of(context);
    String? reason;
    if (JobMachine.requiresReason(to)) {
      reason = await _askReason(to);
      if (reason == null) return;
    }
    setState(() => _busy = true);
    try {
      final b = await ref.read(bookingsRepoProvider).transition(
          widget.id, to,
          knownFrom: _status, actorRole: role, reason: reason);
      setState(() {
        _history.add(StatusEvent(
            from: _status,
            to: b.status,
            actor: role,
            at: DateTime.now(),
            reason: reason));
        _status = b.status;
      });
      ref.read(notificationCenterProvider).record(
          type: NotificationTypes.booking,
          title: 'Booking ${b.status}',
          body: '${widget.id} moved to ${b.status} by $role.');
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e is Failure
              ? userMessage(e)
              : e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason(String to) async {
    final c = TextEditingController();
    final f = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(to == JobStatus.cancelled
            ? 'Cancel booking'
            : 'Dispute booking'),
        content: Form(
          key: f,
          child: TextFormField(
            controller: c,
            maxLines: 3,
            autofocus: true,
            decoration: InputDecoration(
                hintText: to == JobStatus.cancelled
                    ? 'Cancellation reason (min 5 chars). Refund per backend rules.'
                    : 'Dispute reason (min 5 chars)'),
            validator: (v) => JobMachine.validateReason(to, v),
          ),
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

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(
            authProvider.select((a) => a.valueOrNull?.role)) ??
        AppRoles.customer;
    final next = JobMachine.nextFor(role, _status);
    return Scaffold(
      appBar: RcBackAppBar(
          title: 'Booking ${widget.id}',
          fallback: homeForRole(role)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RcCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Status: $_status',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: RepairColors.headingOn(context))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: RepairColors.tealDim,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(_payState ?? 'PAYMENT PENDING',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: RepairColors.tealBright)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Viewing as $role',
                    style: TextStyle(
                        fontSize: 11,
                        color: RepairColors.tealOn(context))),
                const SizedBox(height: 4),
                Text('Dr. Keith Sterling → Demo Customer',
                    style:
                        TextStyle(fontSize: 12, color: RepairColors.mutedOn(context))),
                Text('Anesthesia Vent Calibration • \$299',
                    style:
                        TextStyle(fontSize: 12, color: RepairColors.mutedOn(context))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('PROGRESS JOB (ROLE-GATED, VALID ONLY)',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: RepairColors.tealOn(context))),
          const SizedBox(height: 8),
          if (next.isEmpty)
            Text(
                'No actions for your role here. Completed jobs reopen only via dispute; cancelled is terminal.',
                style: TextStyle(
                    color: RepairColors.mutedOn(context), fontSize: 12)),
          for (final s in next)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RcButton(
                  label: s == JobStatus.cancelled
                      ? 'Cancel booking…'
                      : s == JobStatus.disputed
                          ? 'Dispute booking…'
                          : 'Move to $s',
                  destructive: s == JobStatus.cancelled,
                  loading: _busy,
                  onPressed: () => _move(s)),
            ),
          const SizedBox(height: 12),
          Text('STATUS HISTORY',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: RepairColors.tealOn(context))),
          const SizedBox(height: 8),
          for (final h in _history)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: RcCard(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text('${h.from} → ${h.to}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: RepairColors.headingOn(context),
                            fontSize: 12)),
                    Text(
                        '${h.actor} • ${_fmt(h.at)}${h.reason != null ? ' • "${h.reason}"' : ''}',
                        style: TextStyle(
                            fontSize: 11,
                            color: RepairColors.mutedOn(context))),
                  ])),
            ),
          const SizedBox(height: 12),
          RcButton(
              label: 'Open chat',
              outline: true,
              onPressed: () =>
                  context.go('${AppRoutes.chat}/conv-${widget.id}')),
          const SizedBox(height: 12),
          PaymentPanel(bookingId: widget.id, amount: 299),
          const SizedBox(height: 12),
          ReviewPanel(bookingId: widget.id, bookingStatus: _status),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class PaymentPanel extends ConsumerStatefulWidget {
  final String bookingId;
  final double amount;
  const PaymentPanel(
      {super.key, this.bookingId = 'b-demo', this.amount = 299});
  @override
  ConsumerState<PaymentPanel> createState() => _PState();
}

class _PState extends ConsumerState<PaymentPanel> {
  String _state = PaymentStatus.pending;
  String? _txId;
  bool _busy = false;
  String? _err;
  @override
  Widget build(BuildContext context) {
    final amountErr =
        PaymentMachine.validateAmount(widget.amount);
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PAYMENT (SERVER-VERIFIED)',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: RepairColors.tealOn(context))),
          Text('State: $_state • \$${widget.amount.toStringAsFixed(2)}',
              style: TextStyle(color: RepairColors.headingOn(context), fontSize: 13)),
          if (_txId != null)
            Text('Tx: $_txId',
                style: TextStyle(
                    fontSize: 10,
                    color: RepairColors.faintOn(context))),
          if (amountErr != null)
            Text(amountErr,
                style: const TextStyle(
                    fontSize: 11, color: RepairColors.red)),
          if (_err != null) ...[
            const SizedBox(height: 6),
            Text(_err!,
                style: const TextStyle(
                    fontSize: 11, color: RepairColors.red)),
          ],
          const SizedBox(height: 8),
          RcButton(
              label: _state == PaymentStatus.failed
                  ? 'Retry failed payment'
                  : 'Start / retry payment',
              loading: _busy,
              onPressed: amountErr != null
                  ? null
                  : () async {
                      setState(() {
                        _busy = true;
                        _err = null;
                      });
                      try {
                        final repo =
                            ref.read(paymentsRepoProvider);
                        final tx = await repo.startPayment(
                            bookingId: widget.bookingId,
                            amount: widget.amount,
                            idempotencyKey:
                                newIdempotencyKey());
                        if (!mounted) return;
                        setState(() {
                          _state = '${tx['status']}';
                          _txId = '${tx['id']}';
                        });
                        final verified = await repo
                            .status('${tx['id']}');
                        if (!mounted) return;
                        setState(() => _state = verified);
                        ref
                            .read(notificationCenterProvider)
                            .record(
                                type:
                                    NotificationTypes.payment,
                                title: 'Payment $verified',
                                body:
                                    '${widget.bookingId} server state: $verified.');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                                  content: Text(
                                      'Payment submitted. Server state: $verified. Never trust client success alone.')));
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() => _err = e is Failure
                              ? userMessage(e)
                              : e.toString());
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _busy = false);
                        }
                      }
                    }),
          const SizedBox(height: 10),
          FutureBuilder(
            future: ref
                .read(paymentsRepoProvider)
                .transactions(widget.bookingId),
            builder: (ctx, snap) {
              if (snap.connectionState ==
                  ConnectionState.waiting) {
                return const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2));
              }
              final txs = snap.data ?? [];
              if (txs.isEmpty) {
              return Text('No transactions yet.',
                  style: TextStyle(
                      fontSize: 11,
                      color: RepairColors.faintOn(context)));
              }
              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text('TRANSACTIONS',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: RepairColors.tealOn(context))),
                  for (final t in txs)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 4),
                      child: Text(
                          '${t.id} • ${t.kind} • \$${t.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: RepairColors.mutedOn(context))),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          FutureBuilder(
            future: ref
                .read(paymentsRepoProvider)
                .invoice(widget.bookingId),
            builder: (ctx, snap) {
              final inv = snap.data;
              if (inv == null) {
              return Text('No invoice yet.',
                  style: TextStyle(
                      fontSize: 11,
                      color: RepairColors.faintOn(context)));
              }
              return Text(
                  'Invoice ${inv.id} • Total \$${inv.total.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: RepairColors.tealOn(context)));
            },
          ),
        ],
      ),
    );
  }
}

class ReviewPanel extends ConsumerStatefulWidget {
  final String bookingId;
  final String bookingStatus;
  const ReviewPanel(
      {super.key, required this.bookingId, required this.bookingStatus});
  @override
  ConsumerState<ReviewPanel> createState() => _RState();
}

class _RState extends ConsumerState<ReviewPanel> {
  int _stars = 5;
  final _c = TextEditingController();
  Review? _mine;
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadMine);
  }

  @override
  void didUpdateWidget(ReviewPanel old) {
    super.didUpdateWidget(old);
    if (old.bookingId != widget.bookingId) _loadMine();
  }

  Future<void> _loadMine() async {
    try {
      final list = await ref
          .read(reviewsRepoProvider)
          .forBooking(widget.bookingId);
      if (!mounted || list.isEmpty) return;
      setState(() {
        _mine = list.first;
        _stars = list.first.rating;
        _c.text = list.first.comment ?? '';
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final gate = ReviewRules.validateEligibility(
        bookingStatus: widget.bookingStatus, isParticipant: true);
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REVIEW (AFTER COMPLETION)',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: RepairColors.tealOn(context))),
          if (gate != null && _mine == null) ...[
            const SizedBox(height: 6),
            Text(gate,
                style: TextStyle(
                    fontSize: 12, color: RepairColors.mutedOn(context))),
          ] else ...[
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                      onPressed: () =>
                          setState(() => _stars = i),
                      icon: Icon(Icons.star,
                          color: i <= _stars
                              ? RepairColors.star
                              : RepairColors.faintOn(context))),
              ],
            ),
            TextField(
                controller: _c,
                maxLines: 2,
                decoration: const InputDecoration(
                    hintText: 'Write review… (optional, max 1000)')),
            if (_err != null) ...[
              const SizedBox(height: 6),
              Text(_err!,
                  style: const TextStyle(
                      fontSize: 11, color: RepairColors.red)),
            ],
            const SizedBox(height: 8),
            RcButton(
                label: _mine == null
                    ? 'Submit review'
                    : 'Update review',
                loading: _busy,
                onPressed: () async {
                  setState(() {
                    _busy = true;
                    _err = null;
                  });
                  try {
                    final repo =
                        ref.read(reviewsRepoProvider);
                    if (_mine == null) {
                      final r = await repo.submit(
                          bookingId: widget.bookingId,
                          rating: _stars,
                          comment: _c.text.trim().isEmpty
                              ? null
                              : _c.text.trim());
                      setState(() => _mine = r);
                    } else {
                      final r = await repo.update(_mine!.id,
                          rating: _stars,
                          comment: _c.text.trim().isEmpty
                              ? null
                              : _c.text.trim());
                      setState(() => _mine = r);
                    }
                    ref
                        .read(notificationCenterProvider)
                        .record(
                            type: NotificationTypes.review,
                            title: 'Review submitted',
                            body:
                                '$_stars stars for ${widget.bookingId}.');
                  } catch (e) {
                    setState(() => _err = e is Failure
                        ? userMessage(e)
                        : e.toString());
                  } finally {
                    if (mounted) {
                      setState(() => _busy = false);
                    }
                  }
                }),
            if (_mine != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(reviewsRepoProvider)
                                .remove(_mine!.id);
                            if (mounted) {
                              setState(() {
                                _mine = null;
                                _c.clear();
                                _stars = 5;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() =>
                                  _err = e.toString());
                            }
                          }
                        },
                        child: Text('Delete',
                            style:
                                TextStyle(fontSize: 11))),
                  ),
                  Expanded(
                    child: TextButton(
                        onPressed: () =>
                            _report(context),
                        child: Text(
                            'Report inappropriate',
                            style:
                                TextStyle(fontSize: 11))),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _report(BuildContext context) async {
    final c = TextEditingController();
    final f = GlobalKey<FormState>();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report review'),
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
              child: Text('Report')),
        ],
      ),
    );
    if (reason == null || _mine == null) return;
    try {
      await ref
          .read(reviewsRepoProvider)
          .report(_mine!.id, reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Reported. Admin will moderate.')));
      }
    } catch (e) {
      if (mounted) setState(() => _err = e.toString());
    }
  }
}
