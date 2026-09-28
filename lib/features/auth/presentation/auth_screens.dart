// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final _f = GlobalKey<FormState>();
  final _e = TextEditingController();
  final _p = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Log in', fallback: AppRoutes.landing),
      body: Form(
        key: _f,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            RcField(label: 'OFFICIAL BUSINESS EMAIL', controller: _e,
                validator: emailValidator, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            RcField(label: 'PASSWORD', controller: _p,
                validator: passwordValidator, obscure: true),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(_err!, style: TextStyle(color: RepairColors.red, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            RcButton(
                label: 'Confirm Dispatch',
                loading: _busy,
                onPressed: () async {
                  if (!_f.currentState!.validate()) return;
                  setState(() { _busy = true; _err = null; });
                  try {
                    await ref.read(authProvider.notifier).login(
                        _e.text.trim(), _p.text);
                    if (!context.mounted) return;
                    final u = ref.read(authProvider).valueOrNull;
                    context.go(u?.role == AppRoles.technician
                        ? AppRoutes.techDashboard
                        : u?.role == AppRoles.admin
                            ? AppRoutes.adminDashboard
                            : AppRoutes.customerHome);
                  } catch (e) {
                    setState(() => _err = e is Failure
                        ? userMessage(e)
                        : 'Login failed. Retry.');
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                }),
            const SizedBox(height: 10),
            RcButton(label: 'Create account', outline: true,
                onPressed: () => context.go(AppRoutes.signup)),
            TextButton(
                onPressed: () => context.go(AppRoutes.forgot),
                child: Text('Forgot password?')),
          ],
        ),
      ),
    );
  }
}

class SignupScreen extends ConsumerStatefulWidget {
  final String? initialRole;
  const SignupScreen({super.key, this.initialRole});
  @override
  ConsumerState<SignupScreen> createState() => _SignupState();
}

class _SignupState extends ConsumerState<SignupScreen> {
  final _f = GlobalKey<FormState>();
  final _n = TextEditingController();
  final _e = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  String _role = AppRoles.customer;
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole == AppRoles.technician ||
        widget.initialRole == AppRoles.customer) {
      _role = widget.initialRole!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Create account', fallback: AppRoutes.login),
      body: Form(
        key: _f,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            RcField(label: 'FULL NAME', controller: _n,
                validator: (v) => requiredValidator(v, 'Name')),
            const SizedBox(height: 12),
            RcField(label: 'EMAIL', controller: _e,
                validator: emailValidator, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            RcField(label: 'PASSWORD (MIN 8, LETTER + NUMBER)', controller: _p,
                validator: strongPasswordValidator, obscure: true),
            const SizedBox(height: 12),
            RcField(label: 'CONFIRM PASSWORD', controller: _c,
                validator: (v) => confirmPasswordValidator(v, _p.text),
                obscure: true),
            const SizedBox(height: 12),
            Text('ROLE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RepairColors.mutedOn(context))),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: AppRoles.customer, label: Text('Customer')),
                ButtonSegment(value: AppRoles.technician, label: Text('Technician')),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(_err!, style: TextStyle(color: RepairColors.red, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            RcButton(
                label: 'Submit Verification Audit',
                loading: _busy,
                onPressed: () async {
                  if (!_f.currentState!.validate()) return;
                  setState(() { _busy = true; _err = null; });
                  try {
                    await ref.read(authProvider.notifier).register(
                        _n.text.trim(), _e.text.trim(), _p.text, _role);
                    if (!context.mounted) return;
                    final created =
                        ref.read(authProvider).valueOrNull;
                    if (created != null && !created.isVerified) {
                      context.go(AppRoutes.verify);
                      return;
                    }
                    context.go(_role == AppRoles.technician
                        ? AppRoutes.techDashboard
                        : AppRoutes.customerHome);
                  } catch (e) {
                    setState(() => _err = e is Failure
                        ? userMessage(e)
                        : 'Signup failed. Retry.');
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

class ForgotScreen extends ConsumerStatefulWidget {
  const ForgotScreen({super.key});
  @override
  ConsumerState<ForgotScreen> createState() => _ForgotState();
}

class _ForgotState extends ConsumerState<ForgotScreen> {
  final c = TextEditingController();
  final f = GlobalKey<FormState>();
  bool _busy = false;
  String? _err;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Reset password', fallback: AppRoutes.login),
      body: Form(
        key: f,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            RcField(label: 'EMAIL', controller: c, validator: emailValidator),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(_err!,
                  style: TextStyle(
                      color: RepairColors.red, fontSize: 12)),
            ],
            if (_sent)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                    'If the account exists, a reset link + 6-digit code was sent. Enter it on Verify, or open the link.',
                    style: TextStyle(
                        fontSize: 12,
                        color: RepairColors.mutedOn(context))),
              ),
            const SizedBox(height: 16),
            RcButton(
                label: 'Send reset link',
                loading: _busy,
                onPressed: () async {
                  if (!f.currentState!.validate()) return;
                  setState(() {
                    _busy = true;
                    _err = null;
                  });
                  try {
                    await ref
                        .read(authProvider.notifier)
                        .forgot(c.text.trim());
                    setState(() => _sent = true);
                  } catch (e) {
                    setState(() => _err = e is Failure
                        ? userMessage(e)
                        : 'Request failed. Retry.');
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                }),
            TextButton(
                onPressed: () => context.go(AppRoutes.verify),
                child: Text('I have a code → Verify')),
          ],
        ),
      ),
    );
  }
}

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});
  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyState();
}

class _VerifyState extends ConsumerState<VerifyOtpScreen> {
  final _f = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Verify account', fallback: AppRoutes.login),
      body: Form(
        key: _f,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
                'Enter the 6-digit verification code sent to your email.',
                style: TextStyle(fontSize: 13, color: RepairColors.mutedOn(context))),
            const SizedBox(height: 12),
            RcField(
                label: '6-DIGIT CODE',
                controller: _code,
                validator: otpValidator,
                keyboard: TextInputType.number),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(_err!,
                  style: TextStyle(
                      color: RepairColors.red, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            RcButton(
                label: 'Verify',
                loading: _busy,
                onPressed: () async {
                  if (!_f.currentState!.validate()) return;
                  setState(() {
                    _busy = true;
                    _err = null;
                  });
                  try {
                    await ref
                        .read(authProvider.notifier)
                        .verify(_code.text.trim());
                    if (!context.mounted) return;
                    final u =
                        ref.read(authProvider).valueOrNull;
                    context.go(u == null
                        ? AppRoutes.login
                        : u.role == AppRoles.technician
                            ? AppRoutes.techDashboard
                            : u.role == AppRoles.admin
                                ? AppRoutes.adminDashboard
                                : AppRoutes.customerHome);
                  } catch (e) {
                    setState(() => _err = e is Failure
                        ? userMessage(e)
                        : 'Invalid code. Retry or resend.');
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                }),
            TextButton(
                onPressed: () async {
                  try {
                    await ref.read(authRepoProvider).resendOtp();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Code resent.')));
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() => _err = e.toString());
                    }
                  }
                },
                child: Text('Resend code')),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});
  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetState();
}

class _ResetState extends ConsumerState<ResetPasswordScreen> {
  final _f = GlobalKey<FormState>();
  final _t = TextEditingController();
  final _p = TextEditingController();
  final _c = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _t.text = widget.token == 'manual' ? '' : widget.token;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Set new password', fallback: AppRoutes.login),
      body: Form(
        key: _f,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            RcField(
                label: 'RESET TOKEN',
                controller: _t,
                validator: resetTokenValidator),
            const SizedBox(height: 12),
            RcField(
                label: 'NEW PASSWORD',
                controller: _p,
                validator: strongPasswordValidator,
                obscure: true),
            const SizedBox(height: 12),
            RcField(
                label: 'CONFIRM PASSWORD',
                controller: _c,
                validator: (v) =>
                    confirmPasswordValidator(v, _p.text),
                obscure: true),
            if (_err != null) ...[
              const SizedBox(height: 10),
              Text(_err!,
                  style: TextStyle(
                      color: RepairColors.red, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            RcButton(
                label: 'Reset password',
                loading: _busy,
                onPressed: () async {
                  if (!_f.currentState!.validate()) return;
                  setState(() {
                    _busy = true;
                    _err = null;
                  });
                  try {
                    await ref
                        .read(authProvider.notifier)
                        .reset(_t.text.trim(), _p.text);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Password reset. Log in.')));
                    context.go(AppRoutes.login);
                  } catch (e) {
                    setState(() => _err = e is Failure
                        ? userMessage(e)
                        : 'Reset failed. Check token.');
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

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RcBackAppBar(
          title: 'Choose your role', fallback: AppRoutes.landing),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('How will you use RepairConnect?',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          RcButton(
              label: 'I need services (Customer)',
              onPressed: () =>
                  context.go('${AppRoutes.signup}?role=${AppRoles.customer}')),
          const SizedBox(height: 10),
          RcButton(
              label: 'I provide services (Technician)',
              outline: true,
              onPressed: () => context.go(
                  '${AppRoutes.signup}?role=${AppRoles.technician}')),
        ],
      ),
    );
  }
}
