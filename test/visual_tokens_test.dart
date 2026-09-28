import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/core/theme/app_theme.dart';
import 'package:repairconnect/theme.dart';

/// Figma visual locks (§4): canonical tokens must never drift.
/// Approved board: deep-navy foundation, surgical-teal accents,
/// 12px panels / 10px cards / 6px inputs+buttons.
void main() {
  int argb(Color c) => c.toARGB32();

  test('palette matches approved Figma board', () {
    expect(argb(RepairColors.pageBg), 0xFF04070D);
    expect(argb(RepairColors.panelBg), 0xFF0A1A2E);
    expect(argb(RepairColors.teal), 0xFF2AB6CE);
    expect(argb(RepairColors.tealBright), 0xFF3ED2E8);
    expect(argb(RepairColors.tealDim), 0xFF123E4A);
    expect(argb(RepairColors.red), 0xFFE5484D);
    expect(argb(RepairColors.copper), 0xFFE8930C);
    expect(argb(RepairColors.copperBg), 0xFF3A2708);
    expect(argb(RepairColors.star), 0xFFF5A623);
    expect(argb(RepairColors.muted), 0xFF8A9BB0);
    expect(argb(RepairColors.faint), 0xFF5E748D);
    expect(argb(RepairColors.border), 0xFF1B3350);
    expect(argb(RepairColors.borderSoft), 0xFF16293F);
  });

  test('decor radii follow spec', () {
    final panel = RepairDecor.panel();
    expect(panel.borderRadius, BorderRadius.circular(12));
    final inner = RepairDecor.inner();
    expect(inner.borderRadius, BorderRadius.circular(9));
  });

  test('material theme carries tokens, not defaults', () {
    final t = buildRepairTheme();
    expect(t.colorScheme.primary, RepairColors.teal);
    expect(t.colorScheme.error, RepairColors.red);
    expect(t.scaffoldBackgroundColor, RepairColors.pageBg);
    final input = t.inputDecorationTheme;
    final border = input.focusedBorder as OutlineInputBorder;
    expect(border.borderRadius, BorderRadius.circular(6));
    expect(border.borderSide.color, RepairColors.teal);
    final err = input.errorBorder as OutlineInputBorder;
    expect(err.borderSide.color, RepairColors.red);
    final elevated = t.elevatedButtonTheme.style!;
    final shape =
        elevated.shape!.resolve({}) as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(6));
  });
}
