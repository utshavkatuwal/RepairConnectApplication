// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/auth/role_guards.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/rc_map.dart';
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
  String _status = JobStatus.requested;
  String? _payState;
  bool _busy = false;
  bool _loading = true;
  String? _loadError;
  String _bookingLine = 'Loading job…';
  Booking? _booking;

  /// Id used for transitions and panels: the resolved job id once a
  /// technician accepted, otherwise the `req-` request id itself.
  String get _target => _booking?.id ?? widget.id;
  bool get _isRequest => _target.startsWith('req-');
  String get _label => _isRequest
      ? 'Request #${_target.substring(4)}'
      : 'Booking #$_target';

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final b = await ref
          .read(bookingsRepoProvider)
          .booking(widget.id);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = null;
        _booking = b;
        _status = b.status;
        final names = [
          if (b.technicianName != null && b.technicianName!.isNotEmpty)
            b.technicianName,
          if (b.customerName != null && b.customerName!.isNotEmpty)
            b.customerName,
        ].join(' → ');
        _bookingLine = [
          if (b.title != null && b.title!.isNotEmpty) b.title,
          if (names.isNotEmpty) names,
          if (b.scheduledAt != null && b.scheduledAt!.isNotEmpty)
            'Scheduled: ${_fmtWhen(b.scheduledAt!)}',
        ].join(' • ');
        if (_bookingLine == 'Loading job…' || _bookingLine.isEmpty) {
          _bookingLine = _label;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_booking == null) {
          _loadError = e is Failure ? userMessage(e) : e.toString();
          _bookingLine = _label;
        }
      });
    }
  }

  final List<StatusEvent> _history = [];

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
          _target, to,
          knownFrom: _status, actorRole: role, reason: reason);
      setState(() {
        _history.add(StatusEvent(
            from: _status,
            to: b.status,
            actor: role,
            at: DateTime.now(),
            reason: reason));
        // Accepting mints the job: _booking now carries its id, so chat
        // and billing below switch from the request to the real job.
        _booking = b;
        _status = b.status;
      });
      ref.read(notificationCenterProvider).record(
          type: NotificationTypes.booking,
          title: 'Booking ${b.status}',
          body: '$_label moved to ${b.status} by $role.');
      if (b.status == JobStatus.accepted) _loadBooking();
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
          title: _label,
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
                      child: Text(
                          _payState ??
                              (_isRequest
                                  ? 'AWAITING TECHNICIAN'
                                  : 'PAYMENT PENDING'),
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
                Text(_bookingLine,
                    style:
                        TextStyle(fontSize: 12, color: RepairColors.mutedOn(context))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_loadError != null) ...[
            RcCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Could not load this booking',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: RepairColors.headingOn(context))),
                  const SizedBox(height: 4),
                  Text(_loadError!,
                      style: TextStyle(
                          fontSize: 12,
                          color: RepairColors.mutedOn(context))),
                  const SizedBox(height: 8),
                  RcButton(
                      label: 'Retry',
                      outline: true,
                      onPressed: () {
                        setState(() {
                          _loading = true;
                          _loadError = null;
                        });
                        _loadBooking();
                      }),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text('PROGRESS JOB (ROLE-GATED, VALID ONLY)',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: RepairColors.tealOn(context))),
          const SizedBox(height: 8),
          if (_loading)
            Text('Loading…',
                style: TextStyle(
                    color: RepairColors.mutedOn(context), fontSize: 12)),
          if (!_loading && next.isEmpty)
            Text(
                'No actions for your role here. Completed jobs reopen only via dispute; cancelled is terminal.',
                style: TextStyle(
                    color: RepairColors.mutedOn(context), fontSize: 12)),
          if (!_loading)
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
          if (_booking != null &&
              _booking!.latitude != null &&
              _booking!.longitude != null) ...[
            Text('JOB LOCATION',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: RepairColors.tealOn(context))),
            const SizedBox(height: 8),
            RcMap(
              centerLat: _booking!.latitude,
              centerLng: _booking!.longitude,
              markerLat: _booking!.latitude,
              markerLng: _booking!.longitude,
              interactive: false,
            ),
            if (_booking!.address != null &&
                _booking!.address!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_booking!.address!,
                    style: TextStyle(
                        fontSize: 11,
                        color: RepairColors.mutedOn(context))),
              ),
            const SizedBox(height: 12),
          ],
          Text('STATUS HISTORY',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: RepairColors.tealOn(context))),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            Text(
                'No transitions yet on this screen — actions you perform appear here.',
                style: TextStyle(
                    color: RepairColors.mutedOn(context), fontSize: 12)),
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
          if (_isRequest) ...[
            // No conversation/bill until a technician accepts: the
            // backend only mints them together with the job.
            Text(
                'Waiting for a technician to accept. Chat and payment open once the job exists.',
                style: TextStyle(
                    fontSize: 12, color: RepairColors.mutedOn(context))),
          ] else ...[
            RcButton(
                label: 'Open chat',
                outline: true,
                onPressed: () =>
                    context.go('${AppRoutes.chat}/conv-$_target')),
            const SizedBox(height: 12),
            PaymentPanel(
                key: ValueKey(_target),
                bookingId: _target,
                jobStatus: _status,
                onState: (s) {
                  if (mounted && _payState != s) {
                    setState(() => _payState = s);
                  }
                }),
            const SizedBox(height: 12),
            ReviewPanel(
                key: ValueKey(_target),
                bookingId: _target,
                bookingStatus: _status),
          ],
        ],
      ),
    );
  }

  /// Backend stores UTC; show the customer's local wall-clock time.
  String _fmtWhen(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final l = dt.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class PaymentPanel extends ConsumerStatefulWidget {
  final String bookingId;
  final String jobStatus;

  /// Reports the server-side bill/payment state to the parent so the
  /// booking header chip never shows a stale placeholder.
  final void Function(String state)? onState;
  const PaymentPanel(
      {super.key,
      required this.bookingId,
      this.jobStatus = '',
      this.onState});
  @override
  ConsumerState<PaymentPanel> createState() => _PState();
}

class _PState extends ConsumerState<PaymentPanel> {
  final _amount = TextEditingController();
  final _billNotes = TextEditingController();
  final _billAmount = TextEditingController();
  String _state = PaymentStatus.pending;
  String? _txId;
  bool _busy = false;
  String? _err;
  String? _provider = 'sandbox';
  Map<String, dynamic>? _bill;

  double? get _parsed => double.tryParse(_amount.text.trim());

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  Future<void> _loadBill() async {
    try {
      final b =
          await ref.read(paymentsRepoProvider).bill(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _bill = b;
        if (b != null && _amount.text.trim().isEmpty) {
          _amount.text = '${b['amount']}';
        }
      });
      widget.onState?.call(_billState());
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  String _billState() {
    final b = _bill;
    if (b == null) return 'NO BILL YET';
    return '${b['status']}' == 'paid'
        ? 'PAID'
        : 'AWAITING PAYMENT';
  }

  Future<void> _createBill() async {
    final amt = double.tryParse(_billAmount.text.trim());
    if (amt == null || amt <= 0) {
      setState(() => _err = 'Enter a valid bill amount');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await ref.read(paymentsRepoProvider).createBill(
          bookingId: widget.bookingId,
          amount: amt,
          notes: _billNotes.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bill issued. The customer can now pay it.')));
      await _loadBill();
    } catch (e) {
      if (mounted) {
        setState(() => _err =
            e is Failure ? userMessage(e) : e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    final billAmount = _bill?['amount'];
    final amount = billAmount != null
        ? (double.tryParse('$billAmount') ?? _parsed)
        : _parsed;
    if (amount == null) return;
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final repo = ref.read(paymentsRepoProvider);
      final tx = await repo.startPayment(
          bookingId: widget.bookingId,
          provider: _provider ?? 'sandbox',
          amount: amount,
          idempotencyKey: newIdempotencyKey());
      if (!mounted) return;
      setState(() {
        _state = '${tx['status']}';
        _txId = '${tx['id']}';
      });
      var verified = await repo.status('${tx['id']}');
      if (!mounted) return;
      // Sandbox: customer confirms in-app to settle through backend.
      if (verified.toLowerCase() != 'successful' &&
          _provider == 'sandbox') {
        final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm sandbox payment'),
            content: Text(
                'Sandbox mode: confirm NPR $amount to settle through the backend wallet (test provider, no real money).'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirm payment')),
            ],
          ),
        );
        if (go == true) {
          await repo.confirm('${tx['id']}');
          verified = await repo.status('${tx['id']}');
        }
      }
      if (!mounted) return;
      setState(() => _state = verified);
      widget.onState?.call(verified.toUpperCase());
      ref.read(notificationCenterProvider).record(
          type: NotificationTypes.payment,
          title: 'Payment $verified',
          body:
              '${widget.bookingId} server state: $verified.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Payment submitted. Server state: $verified.')));
      }
      await _loadBill();
    } catch (e) {
      if (mounted) {
        setState(() => _err = e is Failure
            ? userMessage(e)
            : e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(
            authProvider.select((a) => a.valueOrNull?.role)) ??
        AppRoles.customer;
    final isTech = role == AppRoles.technician;
    final isCustomer = role == AppRoles.customer;
    final jobCompleted = widget.jobStatus == JobStatus.completed;
    final billAmount = _bill?['amount'];
    final billIssued = _bill != null && _bill!['status'] == 'issued';
    final billPaid = _bill != null && _bill!['status'] == 'paid';

    final amountErr = billIssued
        ? null
        : _amount.text.trim().isEmpty
            ? 'Enter the agreed amount'
            : PaymentMachine.validateAmount(_parsed ?? double.nan);

    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PAYMENT (SERVER-VERIFIED)',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: RepairColors.tealOn(context))),
          Text('State: $_state',
              style: TextStyle(
                  color: RepairColors.headingOn(context),
                  fontSize: 13)),
          const SizedBox(height: 8),

          // --- Technician: issue a bill after completion ---
          if (isTech && jobCompleted && _bill == null) ...[
            Text('ISSUE BILL',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: RepairColors.tealOn(context))),
            const SizedBox(height: 6),
            TextFormField(
              controller: _billAmount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'BILL AMOUNT (NPR)'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _billNotes,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'NOTES (OPTIONAL)',
                  hintText: 'Parts, labour, description…'),
            ),
            const SizedBox(height: 8),
            RcButton(
                label: 'Issue bill to customer',
                loading: _busy,
                onPressed: _createBill),
            const SizedBox(height: 8),
          ],

          // --- Bill card (both roles) ---
          if (_bill != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: RepairColors.tealDim,
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'BILL #${_bill!['id']} • NPR $billAmount • ${'${_bill!['status']}'.toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: RepairColors.tealBright)),
                  if (_bill!['notes'] != null &&
                      '${_bill!['notes']}'.isNotEmpty)
                    Text('${_bill!['notes']}',
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                RepairColors.mutedOn(context))),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // --- Customer: pay ---
          if (isCustomer &&
              jobCompleted &&
              (billIssued || _bill == null)) ...[
            if (!billIssued)
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(
                    labelText: 'AMOUNT (NPR)',
                    hintText: 'Agreed job amount'),
                onChanged: (_) => setState(() {}),
              ),
            if (billIssued)
              Text('Pay the issued bill: NPR $billAmount',
                  style: TextStyle(
                      fontSize: 12,
                      color: RepairColors.headingOn(context))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _provider,
              decoration:
                  const InputDecoration(labelText: 'PAYMENT PROVIDER'),
              items: const [
                DropdownMenuItem(
                    value: 'sandbox',
                    child: Text('Sandbox (works locally)')),
                DropdownMenuItem(
                    value: 'esewa', child: Text('eSewa (needs creds)')),
                DropdownMenuItem(
                    value: 'khalti', child: Text('Khalti (needs creds)')),
              ],
              onChanged: (v) =>
                  setState(() => _provider = v ?? 'sandbox'),
            ),
            const SizedBox(height: 6),
          ],

          if (_txId != null)
            Text('Tx: $_txId',
                style: TextStyle(
                    fontSize: 10,
                    color: RepairColors.faintOn(context))),
          if (!billIssued && amountErr != null)
            Text(amountErr,
                style: const TextStyle(
                    fontSize: 11, color: RepairColors.red)),
          if (_err != null) ...[
            const SizedBox(height: 6),
            Text(_err!,
                style: const TextStyle(
                    fontSize: 11, color: RepairColors.red)),
          ],
          if (isCustomer &&
              jobCompleted &&
              (billIssued || _bill == null)) ...[
            const SizedBox(height: 8),
            RcButton(
                label: billPaid
                    ? 'Bill paid'
                    : _state == PaymentStatus.failed
                        ? 'Retry failed payment'
                        : billIssued
                            ? 'Pay bill NPR $billAmount'
                            : 'Start / retry payment',
                loading: _busy,
                onPressed: (amountErr != null ||
                        (billPaid && billIssued))
                    ? null
                    : _pay),
          ],
          if (isTech && !jobCompleted && _bill == null)
            Text(
                'Billing unlocks after you complete the job.',
                style: TextStyle(
                    fontSize: 11,
                    color: RepairColors.faintOn(context))),
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
                  Text('PAYMENT HISTORY',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: RepairColors.tealOn(context))),
                  for (final t in txs)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 4),
                      child: Text(
                          '#${t.id} • ${t.kind} • NPR ${t.amount.toStringAsFixed(2)}',
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
                  'Invoice ${inv.id} • Total NPR ${inv.total.toStringAsFixed(2)}',
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
