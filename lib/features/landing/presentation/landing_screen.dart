// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_mode.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../theme.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: 'Repair ',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: RepairColors.headingOn(context))),
                  TextSpan(
                      text: 'Connect',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: RepairColors.tealOn(context))),
                ])),
                const Spacer(),
                IconButton(
                    tooltip: 'Toggle light/dark',
                    onPressed: () => ref
                        .read(themeModeProvider.notifier)
                        .toggle(),
                    icon: Icon(mode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined)),
                TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: Text('Log in')),
              ],
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: RepairColors.panelBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RepairColors.borderSoft)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PREMIUM VERIFIED TRADE NETWORK',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                          color: RepairColors.tealBright)),
                  SizedBox(height: 10),
                  Text('The Premium Standard of Repair',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: Colors.white)),
                  SizedBox(height: 10),
                  Text(
                      'Verified on-site technicians 24/7. Surgical-grade calibration, medical-device certified, cryptographically locked service records.',
                      style:
                          TextStyle(fontSize: 13, color: RepairColors.body)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            RcButton(
                label: 'Find a technician',
                onPressed: () => context.go(AppRoutes.discovery)),
            const SizedBox(height: 10),
            RcButton(
                label: 'Create account',
                outline: true,
                onPressed: () => context.go(AppRoutes.signup)),
            const SizedBox(height: 18),
            const _HowItWorks(),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () => context.go(AppRoutes.designSystem),
                child: Text('View approved design system →')),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Describe service', 'Category, location, date/time.'),
      ('2', 'Get verified match', 'Rating, credentials, availability.'),
      ('3', 'Track & pay securely', 'Chat, milestones, verified payment.'),
    ];
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOW IT WORKS',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: RepairColors.tealOn(context))),
          const SizedBox(height: 10),
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                      radius: 13,
                      backgroundColor: RepairColors.tealDim,
                      child: Text(s.$1,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: RepairColors.tealBright))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$2,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: RepairColors.headingOn(
                                    context))),
                        Text(s.$3,
                            style: TextStyle(
                                fontSize: 12,
                                color: RepairColors.mutedOn(
                                    context))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
