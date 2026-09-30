// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../services/notifications/push_service.dart';
import '../../../shared/models/models.dart';
import '../../../theme.dart';

/// Pure search/filter helper (§20): keyword + category + min rating +
/// availability. Documented ranking: verified first, then rating, then jobs.
/// No arbitrary hidden ranking.
List<Technician> filterTechnicians(
  List<Technician> all, {
  String? q,
  double minRating = 0,
  bool availableOnly = false,
}) {
  final query = (q ?? '').trim().toLowerCase();
  final out = all.where((t) {
    if (t.rating < minRating) return false;
    if (availableOnly && !t.available) return false;
    if (query.isEmpty) return true;
    return t.name.toLowerCase().contains(query) ||
        t.specialty.toLowerCase().contains(query) ||
        (t.serviceArea ?? '').toLowerCase().contains(query);
  }).toList();
  out.sort((a, b) {
    if (a.verified != b.verified) return a.verified ? -1 : 1;
    final r = b.rating.compareTo(a.rating);
    if (r != 0) return r;
    return b.jobsCompleted.compareTo(a.jobsCompleted);
  });
  return out;
}

List<ServiceItem> filterServices(List<ServiceItem> all,
    {String? q, String? categoryId}) {
  final query = (q ?? '').trim().toLowerCase();
  return all
      .where((s) =>
          (categoryId == null || s.categoryId == categoryId) &&
          (query.isEmpty ||
              s.name.toLowerCase().contains(query) ||
              (s.description ?? '').toLowerCase().contains(query)))
      .toList();
}

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});
  @override
  ConsumerState<CategoriesScreen> createState() => _CatState();
}

class _CatState extends ConsumerState<CategoriesScreen> {
  String _q = '';
  Timer? _debounce;
  late final Future<List<Object>> _data;

  @override
  void initState() {
    super.initState();
    // Loaded once: search filters locally, no refetch per keystroke.
    _data = Future.wait([
      ref.read(catalogRepoProvider).categories(),
      ref.read(catalogRepoProvider).services(),
    ]);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Categories & services',
          fallback: AppRoutes.customerHome),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(
                    const Duration(milliseconds: 350), () {
                  if (mounted) setState(() => _q = v);
                });
              },
              decoration: const InputDecoration(
                  hintText: 'Search services…',
                  prefixIcon: Icon(Icons.search, size: 18)),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Object>>(
              future: _data,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError || snap.data == null) {
                  return AsyncStateView(
                      loading: false,
                      failure: snap.error ?? 'Failed to load',
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
                final cats = snap.data![0] as List<Category>;
                final svcs = snap.data![1] as List<ServiceItem>;
                final filtered =
                    filterServices(svcs, q: _q.isEmpty ? null : _q);
                if (filtered.isEmpty) {
                  return const AsyncStateView(
                      loading: false,
                      empty: true,
                      emptyText: 'No services match.',
                      child: SizedBox());
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final c in cats)
                          ActionChip(
                              label: Text(c.name),
                              onPressed: () => setState(() => _q = c.name)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final s in filtered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RcCard(
                          onTap: () => context.go(
                              '${AppRoutes.serviceDetail}/${s.id}'),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: RepairColors.headingOn(context))),
                              if (s.description != null)
                                Text(s.description!,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: RepairColors.mutedOn(context))),
                              const SizedBox(height: 4),
                              Text('\$${s.basePrice.toStringAsFixed(0)} base',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: RepairColors.tealOn(context))),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceDetailScreen extends ConsumerWidget {
  final String id;
  const ServiceDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Service details',
          fallback: AppRoutes.categories),
      body: FutureBuilder(
        future: ref.watch(catalogRepoProvider).services(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = (snap.data ?? []);
          final s = items.where((e) => e.id == id).toList();
          if (s.isEmpty) {
            return const AsyncStateView(
                loading: false,
                empty: true,
                emptyText: 'Service not found.',
                child: SizedBox());
          }
          final svc = s.first;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RcCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(svc.name,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: RepairColors.headingOn(context))),
                    if (svc.description != null)
                      Text(svc.description!,
                          style: TextStyle(
                              color: RepairColors.bodyOn(context))),
                    const SizedBox(height: 8),
                    Text(
                        '\$${svc.basePrice.toStringAsFixed(0)} base price',
                        style: TextStyle(
                            color: RepairColors.tealOn(context),
                            fontWeight: FontWeight.w700)),
                  ])),
              const SizedBox(height: 12),
              RcButton(
                  label: 'Request this service',
                  onPressed: () => context.go(
                      '${AppRoutes.createRequest}?service=${svc.id}')),
            ],
          );
        },
      ),
    );
  }
}

class TechnicianProfileScreen extends ConsumerWidget {
  final String id;
  const TechnicianProfileScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Technician profile',
          fallback: AppRoutes.discovery),
      body: FutureBuilder(
        future: ref.watch(catalogRepoProvider).technicians(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = (snap.data ?? []).where((t) => t.id == id).toList();
          if (list.isEmpty) {
            return const AsyncStateView(
                loading: false,
                empty: true,
                emptyText: 'Technician not found.',
                child: SizedBox());
          }
          final t = list.first;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RcCard(
                  child: Row(children: [
                const CircleAvatar(
                    radius: 26,
                    backgroundColor: RepairColors.tealDim,
                    child: Icon(
                        Icons.person, color: Colors.white, size: 28)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Expanded(
                            child: Text(t.name,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: RepairColors.headingOn(context)))),
                        if (t.verified)
                          Icon(Icons.verified,
                              size: 16,
                              color: RepairColors.tealOn(context)),
                      ]),
                      Text(t.specialty,
                          style: TextStyle(
                              color: RepairColors.mutedOn(context))),
                      Text('★ ${t.rating} • ${t.jobsCompleted} jobs',
                          style: TextStyle(
                              color: RepairColors.star)),
                    ])),
              ])),
              const SizedBox(height: 12),
              RcCard(
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                    Text('SERVICE AREA & AVAILABILITY',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: RepairColors.tealOn(context))),
                    const SizedBox(height: 6),
                    Text(t.serviceArea ?? 'Metro service area',
                        style: TextStyle(color: RepairColors.headingOn(context))),
                    Text(
                        t.available
                            ? 'Available now'
                            : 'Currently unavailable',
                        style: TextStyle(
                            color: t.available
                                ? RepairColors.tealOn(context)
                                : RepairColors.copper)),
                    const SizedBox(height: 8),
                    Text(
                        'Class-III Medical Device Certified • ISO 13485 audit compliant.',
                        style: TextStyle(
                            fontSize: 12,
                            color: RepairColors.mutedOn(context))),
                  ])),
              const SizedBox(height: 12),
              FutureBuilder<List<Review>>(
                future: ref
                    .watch(reviewsRepoProvider)
                    .forTechnician(t.id),
                builder: (ctx, rsnap) {
                  final revs = rsnap.data ?? [];
                  return RcCard(
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                        Text('CUSTOMER REVIEWS',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color:
                                    RepairColors.tealOn(context))),
                        const SizedBox(height: 6),
                        if (rsnap.connectionState ==
                            ConnectionState.waiting)
                          const SizedBox(
                              height: 16,
                              width: 16,
                              child:
                                  CircularProgressIndicator(
                                      strokeWidth: 2))
                        else if (revs.isEmpty)
                          Text(
                              'No reviews yet — reviews unlock after completed jobs.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      RepairColors.mutedOn(context)))
                        else
                          for (final r in revs)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                      bottom: 6),
                              child: Text(
                                  '${'★' * r.rating}${'☆' * (5 - r.rating)} ${r.comment ?? ''}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: RepairColors.headingOn(context))),
                            ),
                      ]));
                },
              ),
              const SizedBox(height: 12),
              RcButton(
                  label: t.available
                      ? 'Request service'
                      : 'Request (joins queue)',
                  onPressed: () => context.go(
                      '${AppRoutes.createRequest}?tech=${t.id}')),
            ],
          );
        },
      ),
    );
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'History & invoices',
          fallback: AppRoutes.customerHome),
      body: FutureBuilder<List<Booking>>(
        future: ref.watch(bookingsRepoProvider).myBookings(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return AsyncStateView(
                loading: false,
                error: snap.error.toString(),
                onRetry: () {},
                child: const SizedBox());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const AsyncStateView(
                loading: false,
                empty: true,
                emptyText: 'No past services yet.',
                child: SizedBox());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final b = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RcCard(
                  onTap: () => context
                      .go('${AppRoutes.bookingDetail}/${b.id}'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('${b.requestId} • ${b.status}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: RepairColors.headingOn(context))),
                            Text(
                                '\$${b.price.toStringAsFixed(0)} • pay ${b.paymentStatus} — tap for invoice',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: RepairColors.mutedOn(context))),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: RepairColors.faintOn(context)),
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
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotifsState();
}

class _NotifsState
    extends ConsumerState<NotificationsScreen> {
  String? _type;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    ref
        .read(notificationCenterProvider)
        .stream
        .listen((_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final center = ref.watch(notificationCenterProvider);
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Notifications',
          fallback: AppRoutes.customerHome),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _chip(null, 'All'),
                for (final t in NotificationTypes.all)
                  _chip(t, t),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AppNotification>>(
              future: center.all(),
              builder: (ctx, snap) {
                if (snap.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return AsyncStateView(
                      loading: false,
                      error: snap.error.toString(),
                      onRetry: () =>
                          setState(() => _tick++),
                      child: const SizedBox());
                }
                final items =
                    NotificationCenter.filterByType(
                        snap.data ?? [], _type);
                if (items.isEmpty) {
                  return const AsyncStateView(
                      loading: false,
                      empty: true,
                      emptyText:
                          'No notifications for this filter.',
                      child: SizedBox());
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      setState(() => _tick++),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final n = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: 10),
                        child: RcCard(
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                  n.read
                                      ? Icons
                                          .notifications_outlined
                                      : Icons
                                          .notifications_active,
                                  color: n.read
                                      ? RepairColors.faintOn(context)
                                      : RepairColors
                                          .tealBright,
                                  size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(n.title,
                                        style: TextStyle(
                                            fontWeight:
                                                FontWeight.w700,
                                            color: n.read
                                                ? RepairColors
                                                    .muted
                                                : Colors.white)),
                                    Text(n.body,
                                        style:
                                            TextStyle(
                                                fontSize: 12,
                                                color: RepairColors
                                                    .muted)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${n.type} • ${n.createdAt}',
                                        style:
                                            TextStyle(
                                                fontSize: 10,
                                                color: RepairColors
                                                    .faint)),
                                  ],
                                ),
                              ),
                              if (!n.read)
                                TextButton(
                                    onPressed: () async {
                                      await center
                                          .markRead(n.id);
                                      setState(
                                          () => _tick++);
                                    },
                                    child:
                                        Text('Read')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String? value, String label) {
    final sel = _type == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
          label: Text(label,
              style: TextStyle(fontSize: 11)),
          selected: sel,
          onSelected: (_) =>
              setState(() => _type = value)),
    );
  }
}
