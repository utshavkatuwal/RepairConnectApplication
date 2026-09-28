// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/auth/role_guards.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_mode.dart';
import '../../../core/widgets/location_picker.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../services/location/location_service.dart';
import '../../../shared/models/models.dart';
import '../../../theme.dart';

final _catalogProvider = FutureProvider((ref) async {
  final repo = ref.watch(catalogRepoProvider);
  final cats = await repo.categories();
  final techs = await repo.technicians();
  return (cats, techs);
});

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});
  @override
  ConsumerState<CustomerHomeScreen> createState() =>
      _HomeState();
}

class _HomeState extends ConsumerState<CustomerHomeScreen> {
  late final Future<List<AppNotification>> _notifs;
  late final Future<LatLng?> _pos;

  @override
  void initState() {
    super.initState();
    // Memoized once per screen instance: no refetch storm on rebuilds.
    _notifs = ref.read(notificationsRepoProvider).list();
    _pos = ref.read(locationServiceProvider).currentPosition();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_catalogProvider);
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('RepairConnect'),
        actions: [
          IconButton(
              tooltip: 'Toggle light/dark',
              onPressed: () =>
                  ref.read(themeModeProvider.notifier).toggle(),
              icon: Icon(mode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined)),
          FutureBuilder(
            future: _notifs,
            builder: (ctx, snap) {
              final unread =
                  (snap.data ?? []).where((n) => !n.read).length;
              return Stack(
                children: [
                  IconButton(
                      onPressed: () =>
                          context.go(AppRoutes.notifications),
                      icon: Icon(
                          Icons.notifications_outlined)),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                          radius: 8,
                          backgroundColor: RepairColors.red,
                          child: Text('$unread',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white))),
                    ),
                ],
              );
            },
          ),
          IconButton(
              onPressed: () => context.go(AppRoutes.history),
              icon: Icon(Icons.receipt_long_outlined)),
          IconButton(
              onPressed: () => context.go(AppRoutes.profile),
              icon: Icon(Icons.person_outline)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) context.go(AppRoutes.discovery);
          if (i == 2) context.go(AppRoutes.createRequest);
          if (i == 3) context.go(AppRoutes.history);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Request'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'History'),
        ],
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncStateView(
            loading: false, error: e.toString(),
            onRetry: () => ref.invalidate(_catalogProvider),
            child: const SizedBox()),
        data: (v) {
          final (cats, techs) = v;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Good day 👋',
                  style: TextStyle(fontSize: 13, color: RepairColors.mutedOn(context))),
              Text('What needs repair?',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: RepairColors.headingOn(context))),
              const SizedBox(height: 12),
              TextField(
                readOnly: true,
                onTap: () => context.go(AppRoutes.discovery),
                decoration: const InputDecoration(
                    hintText: 'Search hardware requisitions…',
                    prefixIcon: Icon(Icons.search, size: 18)),
              ),
              const SizedBox(height: 12),
              FutureBuilder<LatLng?>(
                future: _pos,
                builder: (ctx, snap) {
                  final p = snap.data;
                  return Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 14,
                          color: RepairColors.tealOn(context)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            p == null
                                ? 'Location unavailable — enter manually in request'
                                : 'Near ${p.label} • tap Search for nearby techs',
                            style: TextStyle(
                                fontSize: 11,
                                color: RepairColors.mutedOn(context))),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              RcCard(
                onTap: () =>
                    context.go('${AppRoutes.bookingDetail}/b-active'),
                child: Row(
                  children: [
                    Icon(Icons.bolt_outlined,
                        color: RepairColors.tealOn(context)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('Active booking',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: RepairColors.tealOn(context))),
                          Text('IPC-9028-T • IN PROGRESS',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: RepairColors.headingOn(context))),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: RepairColors.faintOn(context)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Categories',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: RepairColors.headingOn(context))),
                  TextButton(
                      onPressed: () => context.go(AppRoutes.categories),
                      child: Text('View all')),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cats.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ActionChip(
                      label: Text(cats[i].name),
                      onPressed: () => context.go(
                          '${AppRoutes.discovery}?cat=${cats[i].id}')),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Verified technicians',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: RepairColors.headingOn(context))),
                  TextButton(
                      onPressed: () => context.go(AppRoutes.discovery),
                      child: Text('View all')),
                ],
              ),
              // Lazy-built rows: only visible cards inflate, even with
              // hundreds of technicians (no expensive work in build).
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: techs.length,
                itemBuilder: (_, index) {
                  final t = techs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RcCard(
                      onTap: () =>
                          context.go('${AppRoutes.techDetail}/${t.id}'),
                      child: Row(
                        children: [
                          const CircleAvatar(
                              backgroundColor: RepairColors.tealDim,
                              child: Icon(Icons.person,
                                  color: Colors.white)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                        child: Text(t.name,
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.w700,
                                                color: RepairColors.headingOn(context)))),
                                    if (t.verified)
                                      Icon(Icons.verified,
                                          size: 14,
                                          color: RepairColors
                                              .tealBright),
                                  ],
                                ),
                                Text(t.specialty,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: RepairColors.mutedOn(context))),
                                Text(
                                    '★ ${t.rating} • ${t.jobsCompleted} jobs',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: RepairColors.star)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              RcButton(
                  label: 'Create service request',
                  onPressed: () => context.go(AppRoutes.createRequest)),
            ],
          );
        },
      ),
    );
  }
}

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});
  @override
  ConsumerState<DiscoveryScreen> createState() => _DState();
}

class _DState extends ConsumerState<DiscoveryScreen> {
  String _q = '';
  String? _cat;
  double _minRating = 0;
  bool _availableOnly = false;
  bool _nearMe = false;
  LatLng? _pos;
  String? _locErr;
  Timer? _debounce;
  late Future<List<Category>> _catsFuture;
  Future<List<Technician>>? _techFuture;

  @override
  void initState() {
    super.initState();
    _catsFuture = ref.read(catalogRepoProvider).categories();
    _refreshTechs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String v) {
    _debounce?.cancel();
    // 400ms debounce: one fetch per pause, not per keystroke.
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _q = v;
        _refreshTechs();
      });
    });
  }

  void _refreshTechs() {
    _techFuture = ref.read(catalogRepoProvider).technicians(
        q: _q.isEmpty ? null : _q, lat: _pos?.lat, lng: _pos?.lng);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Find technicians',
          fallback: AppRoutes.customerHome),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: _onQuery,
              decoration: const InputDecoration(
                  hintText: 'Keyword, specialty, location…',
                  prefixIcon: Icon(Icons.search, size: 18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FutureBuilder<List<Category>>(
              future: _catsFuture,
              builder: (ctx, snap) {
                final cats = snap.data ?? [];
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _cat,
                        decoration: const InputDecoration(
                            labelText: 'CATEGORY'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All')),
                          for (final c in cats)
                            DropdownMenuItem(
                                value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() {
                          _cat = v;
                          _refreshTechs();
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        initialValue: _minRating,
                        decoration: const InputDecoration(
                            labelText: 'MIN RATING'),
                        items: const [
                          DropdownMenuItem(
                              value: 0, child: Text('Any')),
                          DropdownMenuItem(
                              value: 4.5, child: Text('4.5+')),
                          DropdownMenuItem(
                              value: 4.8, child: Text('4.8+')),
                        ],
                        onChanged: (v) => setState(() {
                          _minRating = v ?? 0;
                          _refreshTechs();
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Available only',
                    style: TextStyle(
                        fontSize: 12,
                        color: RepairColors.mutedOn(context))),
                Switch(
                    value: _availableOnly,
                    onChanged: (v) => setState(() {
                          _availableOnly = v;
                          _refreshTechs();
                        })),
                Text('Near me',
                    style: TextStyle(
                        fontSize: 12,
                        color: RepairColors.mutedOn(context))),
                Switch(
                    value: _nearMe,
                    onChanged: (v) async {
                      setState(() {
                        _nearMe = v;
                        _locErr = null;
                      });
                      if (!v) {
                        setState(() {
                          _pos = null;
                          _refreshTechs();
                        });
                        return;
                      }
                      final svc =
                          ref.read(locationServiceProvider);
                      if (!await svc.ensurePermission()) {
                        setState(() {
                          _nearMe = false;
                          _locErr =
                              'Permission denied — showing all areas.';
                        });
                        return;
                      }
                      final p = await svc.currentPosition();
                      if (p == null) {
                        setState(() {
                          _nearMe = false;
                          _locErr =
                              'GPS unavailable — showing all areas.';
                        });
                        return;
                      }
                      setState(() {
                        _pos = p;
                        _refreshTechs();
                      });
                    }),
              ],
            ),
          ),
          if (_locErr != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_locErr!,
                  style: TextStyle(
                      fontSize: 11,
                      color: RepairColors.copper)),
            ),
          if (_pos != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Center: ${_pos!.label} • ranking server-side',
                  style: TextStyle(
                      fontSize: 11,
                      color: RepairColors.tealOn(context))),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Spacer(),
                TextButton(
                    onPressed: () =>
                        context.go(AppRoutes.categories),
                    child: Text('Browse services')),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Technician>>(
              future: _techFuture,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return AsyncStateView(
                      loading: false,
                      failure: snap.error,
                      onRetry: () => setState(() => _refreshTechs()),
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
                final all = snap.data ?? [];
                // Category narrows via specialty match in fake mode;
                // real backend filters server-side with lat/lng.
                final list = all
                    .where((t) =>
                        t.rating >= _minRating &&
                        (!_availableOnly || t.available))
                    .toList()
                  ..sort((a, b) {
                    if (a.verified != b.verified) {
                      return a.verified ? -1 : 1;
                    }
                    return b.rating.compareTo(a.rating);
                  });
                if (list.isEmpty) {
                  return const AsyncStateView(
                      loading: false,
                      empty: true,
                      emptyText: 'No technicians match. Try another keyword.',
                      child: SizedBox());
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final t = list[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RcCard(
                        onTap: () => context.go(
                            '${AppRoutes.techDetail}/${t.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(t.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: RepairColors.headingOn(context))),
                              ),
                              if (t.verified)
                                Icon(Icons.verified,
                                    size: 14,
                                    color: RepairColors.tealOn(context)),
                            ]),
                            Text(
                                '${t.specialty} • ${t.available ? 'Available' : 'Busy'}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: RepairColors.mutedOn(context))),
                            Text('★ ${t.rating} • ${t.jobsCompleted} jobs',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: RepairColors.star)),
                            const SizedBox(height: 8),
                            RcButton(
                                label: 'View profile',
                                onPressed: () => context.go(
                                    '${AppRoutes.techDetail}/${t.id}')),
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

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});
  @override
  ConsumerState<CreateRequestScreen> createState() => _CState();
}

class _CState extends ConsumerState<CreateRequestScreen> {
  final _f = GlobalKey<FormState>();
  final _desc = TextEditingController();
  final _addr = TextEditingController();
  String _serviceId = 's1';
  bool _busy = false;
  String? _err;
  LatLng? _pos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'New service request',
          fallback: AppRoutes.customerHome),
      body: Form(
        key: _f,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FutureBuilder<List<ServiceItem>>(
              future: ref.watch(catalogRepoProvider).services(),
              builder: (ctx, snap) {
                final List<ServiceItem> items = snap.data ?? [];
                final valid = items.any((s) => s.id == _serviceId);
                return DropdownButtonFormField<String>(
                  initialValue: valid ? _serviceId : null,
                  items: items
                      .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.name} — \$${s.basePrice}')))
                      .toList(),
                  onChanged: (v) => setState(() => _serviceId = v ?? _serviceId),
                  decoration:
                      const InputDecoration(labelText: 'SERVICE / CATEGORY'),
                );
              },
            ),
            const SizedBox(height: 12),
            RcField(
                label: 'PROBLEM DETAILS',
                controller: _desc,
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().length < 10) ? 'Describe the problem (min 10 chars)' : null),
            const SizedBox(height: 12),
            RcField(label: 'LOCATION', controller: _addr,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Location required' : null),
            const SizedBox(height: 12),
            LocationPicker(
              onChanged: (pos, resolved) {
                setState(() => _pos = pos);
                if (resolved.isNotEmpty && _addr.text.trim().isEmpty) {
                  _addr.text = resolved;
                }
              },
            ),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(_err!,
                  style: const TextStyle(
                      color: RepairColors.red, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            RcButton(
                label: 'Submit request',
                loading: _busy,
                onPressed: () async {
                  if (!_f.currentState!.validate()) return;
                  setState(() { _busy = true; _err = null; });
                  try {
                    final req = await ref
                        .read(bookingsRepoProvider)
                        .createRequest(
                            serviceId: _serviceId,
                            description: _desc.text.trim(),
                            address: _pos == null
                                ? _addr.text.trim()
                                : '${_addr.text.trim()} [${_pos!.label}]');
                    if (!context.mounted) return;
                    context.go('${AppRoutes.bookingDetail}/${req.id}');
                  } catch (e) {
                    setState(() => _err = e.toString());
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                }),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final mode = ref.watch(themeModeProvider);
    final home = homeForRole(user?.role ?? AppRoles.customer);
    return Scaffold(
      appBar: RcBackAppBar(title: 'Profile', fallback: home),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          RcCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(user?.name ?? 'Demo User',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: RepairColors.headingOn(context))),
                Text(user?.email ?? '',
                    style: TextStyle(
                        color: RepairColors.mutedOn(context))),
                Text('Role: ${user?.role ?? ''}',
                    style: TextStyle(
                        fontSize: 12,
                        color: RepairColors.tealOn(context))),
              ])),
          const SizedBox(height: 12),
          RcCard(
              child: Row(
            children: [
              Icon(
                  mode == ThemeMode.dark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  color: RepairColors.tealOn(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: RepairColors.headingOn(
                                context))),
                    Text(
                        mode == ThemeMode.dark
                            ? 'Dark (approved blueprint)'
                            : 'Light (light surfaces spec)',
                        style: TextStyle(
                            fontSize: 12,
                            color: RepairColors.mutedOn(context))),
                  ],
                ),
              ),
              Switch(
                  value: mode == ThemeMode.light,
                  onChanged: (_) => ref
                      .read(themeModeProvider.notifier)
                      .toggle()),
            ],
          )),
          const SizedBox(height: 12),
          RcButton(
              label: 'Log out',
              outline: true,
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.login);
              }),
        ],
      ),
    );
  }
}
