import 'package:flutter/material.dart';

class RepairColors {
  static const pageBg = Color(0xFF04070D);
  static const panelBg = Color(0xFF0A1A2E);
  static const panelBg2 = Color(0xFF0C2038);
  static const cardBg = Color(0xFF071120);
  static const innerBg = Color(0xFF0A1528);
  static const fieldBg = Color(0xFF0B1A2E);
  static const border = Color(0xFF1B3350);
  static const borderSoft = Color(0xFF16293F);

  static const teal = Color(0xFF2AB6CE);
  static const tealBright = Color(0xFF3ED2E8);
  static const tealDim = Color(0xFF123E4A);
  static const tealText = Color(0xFF5EEAD4);

  static const navyLabel = Color(0xFF7D93AC);
  static const muted = Color(0xFF8A9BB0);
  static const faint = Color(0xFF5E748D);
  static const heading = Color(0xFFF1F5F9);
  static const body = Color(0xFFB9C6D6);

  static const red = Color(0xFFE5484D);
  static const redBg = Color(0xFF3A1A22);
  static const copper = Color(0xFFE8930C);
  static const copperBg = Color(0xFF3A2708);
  static const offWhite = Color(0xFFF1F5F9);
  static const lightCard = Color(0xFFF8FAFC);
  static const star = Color(0xFFF5A623);

  static const lightPanelBg = Color(0xFFFFFFFF);
  static const lightFieldBg = Color(0xFFF1F5F9);
  static const lightBorder = Color(0xFFE2E8F0);

  static const chatMine = Color(0xFF155E6B);
  static const chatTheirs = Color(0xFF12263C);

  // Light-mode ink (Figma LIGHT SYSTEM SURFACES). Teal deepens for
  // contrast on white; body text goes slate.
  static const lightScaffold = Color(0xFFF1F5F9);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightField = Color(0xFFF8FAFC);
  static const lightTeal = Color(0xFF0E9DB2);
  static const lightInk = Color(0xFF0F172A);
  static const lightBody = Color(0xFF334155);
  static const lightMuted = Color(0xFF64748B);

  /// Mode-aware text/accent colors. Use these (not raw white/tealBright)
  /// for any text painted on app surfaces so both modes stay legible.
  static Color headingOn(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? heading
          : lightInk;

  static Color bodyOn(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? body
          : lightBody;

  static Color mutedOn(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? muted
          : lightMuted;

  static Color faintOn(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? faint
          : lightMuted;

  static Color tealOn(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? tealBright
          : lightTeal;

  static Color panelOn(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? panelBg
          : lightSurface;

  static Color fieldOn(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? fieldBg
          : lightField;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

class RepairText {
  static TextStyle microTeal({double size = 9}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: RepairColors.tealBright,
      );
  static TextStyle microMuted({double size = 9}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: RepairColors.faint,
      );
  static const headingLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: RepairColors.heading,
    height: 1.15,
  );
  static const headingMed = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: RepairColors.heading,
    height: 1.25,
  );
  static const headingSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    color: RepairColors.heading,
  );
  static const bodySmall = TextStyle(
    fontSize: 11,
    height: 1.55,
    color: RepairColors.body,
  );
  static const bodyTiny = TextStyle(
    fontSize: 10,
    height: 1.5,
    color: RepairColors.muted,
  );
  static const monoTiny = TextStyle(
    fontSize: 9.5,
    height: 1.5,
    color: RepairColors.muted,
    fontFamily: 'monospace',
  );
}

class RepairDecor {
  static BoxDecoration panel({Color? color}) => BoxDecoration(
        color: color ?? RepairColors.panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RepairColors.border.withValues(alpha: 0.55)),
      );
  static BoxDecoration inner({Color? color, Color? border}) => BoxDecoration(
        color: color ?? RepairColors.cardBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border ?? RepairColors.borderSoft),
      );
}
