import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/connectivity.dart';
import '../../theme.dart';

/// Persistent offline bar (§25). Shows on every screen via the app builder.
/// Never claims success while the backend is unreachable — actions keep
/// their own retry affordances.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final net = ref.watch(netStateProvider).valueOrNull;
    if (net != NetState.offline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: RepairColors.copperBg,
      child: const Row(
        children: [
          Icon(Icons.wifi_off, size: 14, color: RepairColors.copper),
          SizedBox(width: 8),
          Expanded(
            child: Text(
                'You are offline. Changes will fail — retry when reconnected.',
                style: TextStyle(fontSize: 11, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
