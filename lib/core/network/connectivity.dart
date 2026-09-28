import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/failures.dart';

/// Network presence (§21, §25). connectivity_plus reports interface state;
/// Dio failures remain the source of truth for "server unreachable".
enum NetState { online, offline }

final connectivityProvider = Provider((_) => Connectivity());

final netStateProvider =
    StreamProvider<NetState>((ref) async* {
  final c = ref.watch(connectivityProvider);
  final first = await c.checkConnectivity();
  yield first.contains(ConnectivityResult.none)
      ? NetState.offline
      : NetState.online;
  await for (final r in c.onConnectivityChanged) {
    yield r.contains(ConnectivityResult.none)
        ? NetState.offline
        : NetState.online;
  }
});

/// Display contract for every async screen (§21): loading/success/empty +
/// error/offline/unauthorized/not-found, matched to the approved design.
class FailureDisplay {
  final String message;
  final bool isOffline;
  final bool isAuth;
  final bool isNotFound;
  const FailureDisplay(
      {required this.message,
      this.isOffline = false,
      this.isAuth = false,
      this.isNotFound = false});
}

FailureDisplay displayFor(Object e) {
  if (e is AuthFailure) {
    return FailureDisplay(message: userMessage(e), isAuth: true);
  }
  if (e is NotFoundFailure) {
    return FailureDisplay(message: userMessage(e), isNotFound: true);
  }
  if (e is NetworkFailure) {
    final m = e.message.toLowerCase();
    final offline = m.contains('no connection') ||
        m.contains('offline') ||
        m.contains('unreachable');
    return FailureDisplay(message: userMessage(e), isOffline: offline);
  }
  if (e is Failure) return FailureDisplay(message: userMessage(e));
  final m = e.toString().toLowerCase();
  if (m.contains('no connection') || m.contains('socket')) {
    return const FailureDisplay(
        message: 'No connection to server. Retry when online.',
        isOffline: true);
  }
  return FailureDisplay(message: e.toString());
}
