import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../network/connectivity.dart';

/// App bar with a guaranteed back affordance. go_router `go` replaces the
/// stack, so `pop` alone would do nothing — fall back to [fallback].
class RcBackAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String fallback;
  final List<Widget>? actions;
  const RcBackAppBar(
      {super.key,
      required this.title,
      required this.fallback,
      this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(fallback);
          }
        },
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);
}

class RcButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outline;
  final bool destructive;
  final bool loading;
  const RcButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.outline = false,
      this.destructive = false,
      this.loading = false});

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(label);
    if (destructive) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
              backgroundColor: RepairColors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6))),
          child: child,
        ),
      );
    }
    if (outline) {
      return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
              onPressed: loading ? null : onPressed, child: child));
    }
    return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
            onPressed: loading ? null : onPressed, child: child));
  }
}

class RcField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscure;
  final TextInputType? keyboard;
  final int maxLines;
  const RcField(
      {super.key,
      required this.label,
      required this.controller,
      this.validator,
      this.obscure = false,
      this.keyboard,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: RepairColors.mutedOn(context))),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscure,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: TextStyle(
              fontSize: 13, color: RepairColors.headingOn(context)),
          decoration: InputDecoration(hintText: label),
        ),
      ],
    );
  }
}

class RcCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const RcCard({super.key, required this.child, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RepairColors.panelOn(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: RepairColors.isDark(context)
                ? RepairColors.borderSoft
                : RepairColors.lightBorder),
      ),
      child: child,
    );
    if (onTap == null) return c;
    return InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(10), child: c);
  }
}

class AsyncStateView extends StatelessWidget {
  final bool loading;
  final String? error;
  final Object? failure;
  final bool empty;
  final String emptyText;
  final VoidCallback? onRetry;
  final VoidCallback? onLogin;
  final Widget child;
  const AsyncStateView(
      {super.key,
      required this.loading,
      this.error,
      this.failure,
      this.empty = false,
      this.emptyText = 'Nothing here yet.',
      this.onRetry,
      this.onLogin,
      required this.child});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final disp = failure != null
        ? displayFor(failure!)
        : error != null
            ? FailureDisplay(message: error!)
            : null;
    if (disp != null) {
      final icon = disp.isOffline
          ? Icons.wifi_off
          : disp.isAuth
              ? Icons.lock_outline
              : disp.isNotFound
                  ? Icons.search_off
                  : Icons.error_outline;
      final color = disp.isOffline
          ? RepairColors.copper
          : disp.isAuth
              ? RepairColors.tealOn(context)
              : RepairColors.red;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(disp.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: RepairColors.bodyOn(context),
                    fontSize: 12)),
            const SizedBox(height: 10),
            if (onRetry != null)
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            if (disp.isAuth && onLogin != null)
              TextButton(onPressed: onLogin, child: const Text('Log in again')),
          ],
        ),
      );
    }
    if (empty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                color: RepairColors.faintOn(context), size: 30),
            const SizedBox(height: 8),
            Text(emptyText,
                style: TextStyle(
                    color: RepairColors.mutedOn(context),
                    fontSize: 12)),
          ],
        ),
      );
    }
    return child;
  }
}

/// Selectable card-style toggle (e.g. Immediate vs Schedule).
class ChoiceBox extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const ChoiceBox(
      {super.key,
      required this.label,
      required this.selected,
      this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? RepairColors.tealDim
              : RepairColors.panelOn(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? RepairColors.tealBright
                  : RepairColors.isDark(context)
                      ? RepairColors.borderSoft
                      : RepairColors.lightBorder),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? RepairColors.tealBright
                      : RepairColors.mutedOn(context))),
        ),
      ),
    );
  }
}
