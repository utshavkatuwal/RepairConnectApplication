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

// Core singletons.
final sessionStoreProvider = Provider((_) => SessionStore());
final dioClientProvider =
    Provider((ref) => DioClient(sessions: ref.watch(sessionStoreProvider)));
final authRepoProvider = Provider(
    (ref) => AuthRepository(ref.watch(dioClientProvider), ref.watch(sessionStoreProvider)));
final catalogRepoProvider =
    Provider((ref) => CatalogRepository(ref.watch(dioClientProvider)));
final bookingsRepoProvider =
    Provider((ref) => BookingsRepository(ref.watch(dioClientProvider)));
final chatServiceProvider = Provider<ChatService>((_) => InMemoryChatService());
final locationServiceProvider =
    Provider<LocationService>((_) => FakeLocationService());
// Production swap (no UI change): CartoLocationService(api: dio),
// ApiChatService(dio), ApiPaymentsRepository(dio), ApiNotificationsRepository(dio).
final pushServiceProvider = Provider<PushService>((_) => NoopPushService());
final paymentsRepoProvider =
    Provider<PaymentsRepository>((_) => FakePaymentsRepository());
final notificationsRepoProvider = Provider<NotificationsRepository>(
    (ref) => ApiNotificationsRepository(ref.watch(dioClientProvider)));
final reviewsRepoProvider = Provider<ReviewsRepository>(
    (ref) => FakeReviewsRepository());
final notificationCenterProvider = Provider<NotificationCenter>(
    (ref) => NotificationCenter(ref.watch(notificationsRepoProvider)));

// Auth state: null = unknown/splash, User = signed in.
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

  /// Server reported 401 and refresh failed: drop to logged-out so the
  /// router sends the user to login (§21 unauthorized state).
  Future<void> expire() async {
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
}

final authProvider =
    StateNotifierProvider<AuthState, AsyncValue<User?>>((ref) => AuthState(ref.watch(authRepoProvider)));
