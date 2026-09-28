// ignore_for_file: unnecessary_underscores
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/role_guards.dart';
import '../core/constants/app_constants.dart';
import '../theme.dart';
import 'providers.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/customer/presentation/customer_screens.dart';
import '../features/customer/presentation/customer_extra_screens.dart';
import '../features/technician/presentation/tech_screens.dart';
import '../features/technician/presentation/tech_extra_screens.dart';
import '../features/admin/presentation/admin_screens.dart';
import '../features/admin/presentation/admin_extra_screens.dart';
import '../features/bookings/presentation/booking_screens.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/design_system/presentation/design_system_screen.dart';
import '../features/landing/presentation/landing_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Select only the user value: router rebuilds on sign in/out,
  // not on transient loading states (fewer rebuilds, no nav resets).
  final user =
      ref.watch(authProvider.select((a) => a.valueOrNull));
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (ctx, state) =>
        guardRoute(state.matchedLocation, user),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.landing, builder: (_, __) => const LandingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.signup,
          builder: (_, s) => SignupScreen(
              initialRole: s.uri.queryParameters['role'])),
      GoRoute(path: AppRoutes.forgot, builder: (_, __) => const ForgotScreen()),
      GoRoute(path: AppRoutes.verify, builder: (_, __) => const VerifyOtpScreen()),
      GoRoute(
          path: '${AppRoutes.reset}/:token',
          builder: (_, s) => ResetPasswordScreen(
              token: s.pathParameters['token'] ?? 'manual')),
      GoRoute(
          path: AppRoutes.reset,
          builder: (_, __) =>
              const ResetPasswordScreen(token: 'manual')),
      GoRoute(path: AppRoutes.role, builder: (_, __) => const RoleSelectScreen()),
      GoRoute(path: AppRoutes.customerHome, builder: (_, __) => const CustomerHomeScreen()),
      GoRoute(path: AppRoutes.discovery, builder: (_, __) => const DiscoveryScreen()),
      GoRoute(path: AppRoutes.categories, builder: (_, __) => const CategoriesScreen()),
      GoRoute(
          path: '${AppRoutes.serviceDetail}/:id',
          builder: (_, s) => ServiceDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(
          path: '${AppRoutes.techDetail}/:id',
          builder: (_, s) => TechnicianProfileScreen(id: s.pathParameters['id']!)),
      GoRoute(path: AppRoutes.history, builder: (_, __) => const HistoryScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.createRequest, builder: (_, __) => const CreateRequestScreen()),
      GoRoute(
          path: '${AppRoutes.bookingDetail}/:id',
          builder: (_, s) => BookingDetailScreen(id: s.pathParameters['id']!)),
      GoRoute(
          path: '${AppRoutes.chat}/:id',
          builder: (_, s) => ChatScreen(conversationId: s.pathParameters['id']!)),
      GoRoute(path: AppRoutes.techDashboard, builder: (_, __) => const TechDashboardScreen()),
      GoRoute(path: AppRoutes.techRequests, builder: (_, __) => const TechRequestsScreen()),
      GoRoute(path: AppRoutes.techProfile, builder: (_, __) => const TechProfileScreen()),
      GoRoute(path: AppRoutes.techEarnings, builder: (_, __) => const EarningsScreen()),
      GoRoute(path: AppRoutes.techAvailability, builder: (_, __) => const AvailabilityScreen()),
      GoRoute(path: AppRoutes.techRegister, builder: (_, __) => const TechRegisterScreen()),
      GoRoute(path: AppRoutes.adminDashboard, builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: AppRoutes.adminUsers, builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: AppRoutes.adminVerify, builder: (_, __) => const AdminVerifyScreen()),
      GoRoute(path: AppRoutes.adminServices, builder: (_, __) => const AdminServicesScreen()),
      GoRoute(path: AppRoutes.adminJobs, builder: (_, __) => const AdminJobsScreen()),
      GoRoute(path: AppRoutes.adminPayments, builder: (_, __) => const AdminPaymentsScreen()),
      GoRoute(path: AppRoutes.adminComplaints, builder: (_, __) => const AdminComplaintsScreen()),
      GoRoute(path: AppRoutes.adminAudit, builder: (_, __) => const AdminAuditScreen()),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(path: AppRoutes.designSystem, builder: (_, __) => const DesignSystemScreen()),
    ],
  );
});

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashState();
}

class _SplashState extends ConsumerState<SplashScreen> {
  bool _stuck = false;

  @override
  void initState() {
    super.initState();
    // Session restore runs in the background only — first navigation is a
    // fixed brand moment and never waits on plugins (secure storage, GPS).
    // ignore: discarded_futures
    ref.read(authProvider.notifier).check();
    // ignore: discarded_futures
    Future.delayed(const Duration(milliseconds: 1500)).then((_) {
      if (!mounted) return;
      context.go(AppRoutes.landing);
    });
    // Last-resort escape hatch: if anything ever strands the user here,
    // offer an explicit way forward instead of a dead screen.
    // ignore: discarded_futures
    Future.delayed(const Duration(seconds: 8)).then((_) {
      if (mounted &&
          GoRouterState.of(context).matchedLocation ==
              AppRoutes.splash) {
        setState(() => _stuck = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: 'Repair ',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: Colors.white)),
                  TextSpan(
                      text: 'Connect',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: RepairColors.tealBright)),
                ]),
              ),
              const SizedBox(height: 8),
              const Text('The Premium Standard of Repair',
                  style: TextStyle(
                      fontSize: 12, color: RepairColors.muted)),
              const SizedBox(height: 24),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              if (_stuck) ...[
                const SizedBox(height: 20),
                const Text('Taking longer than expected.',
                    style: TextStyle(
                        fontSize: 12, color: RepairColors.muted)),
                const SizedBox(height: 8),
                OutlinedButton(
                    onPressed: () =>
                        context.go(AppRoutes.landing),
                    child: const Text('Continue')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
