import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../core/storage/session_store.dart';
import '../shared/models/models.dart';
import '../services/chat/chat_service.dart';
import '../services/location/location_service.dart';
import '../services/notifications/push_service.dart';
import '../services/payments/payments_repo.dart';
import '../features/marketplace/data/repos.dart';
import '../features/auth/data/auth_repo.dart';
import '../features/reviews/data/reviews_repo.dart';
import '../features/technician/data/tech_repo.dart';
import '../features/wallet/data/wallet_repo.dart';
import '../features/admin/data/admin_repo.dart';

// Production dependency graph: every provider resolves to a REAL
// API-backed implementation. Test fakes live in test/helpers/fakes.dart
// and are never referenced here.
final sessionStoreProvider = Provider((_) => SessionStore());
final dioClientProvider =
    Provider((ref) => DioClient(sessions: ref.watch(sessionStoreProvider)));
final authRepoProvider = Provider(
    (ref) => AuthRepository(ref.watch(dioClientProvider), ref.watch(sessionStoreProvider)));
final catalogRepoProvider =
    Provider((ref) => CatalogRepository(ref.watch(dioClientProvider)));
final bookingsRepoProvider =
    Provider((ref) => BookingsRepository(ref.watch(dioClientProvider)));
final chatServiceProvider = Provider<ChatService>(
    (ref) => ApiChatService(ref.watch(dioClientProvider)));
final locationServiceProvider = Provider<LocationService>(
    (ref) => CartoLocationService(api: ref.watch(dioClientProvider)));
final pushServiceProvider = Provider<PushService>((_) => NoopPushService());
final paymentsRepoProvider = Provider<PaymentsRepository>(
    (ref) => ApiPaymentsRepository(ref.watch(dioClientProvider)));
final notificationsRepoProvider = Provider<NotificationsRepository>(
    (ref) => ApiNotificationsRepository(ref.watch(dioClientProvider)));
final notificationCenterProvider = Provider<NotificationCenter>(
    (ref) => NotificationCenter(ref.watch(notificationsRepoProvider)));
final reviewsRepoProvider = Provider<ReviewsRepository>(
    (ref) => ApiReviewsRepository(ref.watch(dioClientProvider)));
final walletRepoProvider = Provider<WalletRepository>(
    (ref) => WalletRepository(ref.watch(dioClientProvider)));
final technicianRepoProvider = Provider<TechnicianRepository>(
    (ref) => TechnicianRepository(ref.watch(dioClientProvider)));
final adminRepoProvider = Provider<AdminRepository>(
    (ref) => AdminRepository(ref.watch(dioClientProvider)));

// Auth state: null = signed out, User = signed in (backend-verified).
class AuthState extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository repo;
  AuthState(this.repo) : super(const AsyncValue.data(null));

  User? get current => state.valueOrNull;

  Future<void> check() async {
    try {
      final u = await repo.me();
      state = AsyncValue.data(u);
    } catch (err, st) {
      state = AsyncValue.error(err, st);
    }
  }

  Future<void> login(String e, String p) async {
    state = const AsyncValue.loading();
    try {
      final u = await repo.login(e, p);
      state = AsyncValue.data(u);
    } catch (err, st) {
      state = AsyncValue.error(err, st);
      rethrow;
    }
  }

  Future<void> register(String n, String e, String p, String role) async {
    state = const AsyncValue.loading();
    try {
      final u = await repo.register(name: n, email: e, password: p, role: role);
      state = AsyncValue.data(u);
    } catch (err, st) {
      state = AsyncValue.error(err, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await repo.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> verify(String email, String code) async {
    state = const AsyncValue.loading();
    try {
      final u = await repo.verifyOtp(email: email, code: code);
      state = AsyncValue.data(u);
    } catch (err, st) {
      state = AsyncValue.error(err, st);
      rethrow;
    }
  }

  Future<void> forgot(String email) => repo.requestPasswordReset(email);

  Future<void> reset(String email, String token, String password) =>
      repo.resetPassword(email: email, token: token, password: password);

  /// Server reported 401 and refresh failed: drop to logged-out so the
  /// router sends the user to login (§21 unauthorized state).
  Future<void> expire() async {
    await repo.logout();
    state = const AsyncValue.data(null);
  }
}

final authProvider =
    StateNotifierProvider<AuthState, AsyncValue<User?>>((ref) => AuthState(ref.watch(authRepoProvider)));
