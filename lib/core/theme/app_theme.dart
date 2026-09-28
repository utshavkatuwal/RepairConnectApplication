import 'package:flutter/material.dart';
import '../../theme.dart';

ThemeData buildRepairTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: RepairColors.pageBg,
    colorScheme: const ColorScheme.dark(
      primary: RepairColors.teal,
      secondary: RepairColors.tealBright,
      surface: RepairColors.panelBg,
      error: RepairColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: RepairColors.panelBg,
      foregroundColor: RepairColors.heading,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RepairColors.fieldBg,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: RepairColors.borderSoft)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: RepairColors.borderSoft)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: RepairColors.teal)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: RepairColors.red)),
      labelStyle: const TextStyle(color: RepairColors.muted, fontSize: 12),
      hintStyle: const TextStyle(color: RepairColors.faint, fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: RepairColors.teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RepairColors.tealBright,
        side: BorderSide(color: RepairColors.teal.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
    ),
    cardTheme: CardThemeData(
      color: RepairColors.panelBg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: RepairColors.borderSoft)),
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: RepairColors.panelBg,
      selectedItemColor: RepairColors.tealBright,
      unselectedItemColor: RepairColors.faint,
    ),
  );
}

/// Light mode from the Figma LIGHT SYSTEM SURFACES spec: white surfaces,
/// light fields, slate ink, deepened teal for contrast.
ThemeData buildRepairLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: RepairColors.lightScaffold,
    colorScheme: const ColorScheme.light(
      primary: RepairColors.lightTeal,
      secondary: RepairColors.lightTeal,
      surface: RepairColors.lightSurface,
      error: RepairColors.red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: RepairColors.lightSurface,
      foregroundColor: RepairColors.lightInk,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RepairColors.lightField,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: RepairColors.lightBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: RepairColors.lightBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: RepairColors.lightTeal)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: RepairColors.red)),
      labelStyle:
          const TextStyle(color: RepairColors.lightMuted, fontSize: 12),
      hintStyle:
          const TextStyle(color: RepairColors.lightMuted, fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: RepairColors.lightTeal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(vertical: 13),
        textStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RepairColors.lightTeal,
        side: const BorderSide(color: RepairColors.lightTeal),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
    ),
    cardTheme: CardThemeData(
      color: RepairColors.lightSurface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: RepairColors.lightBorder)),
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: RepairColors.lightSurface,
      selectedItemColor: RepairColors.lightTeal,
      unselectedItemColor: RepairColors.lightMuted,
    ),
    chipTheme: const ChipThemeData(
      selectedColor: Color(0xFFD9F3F7),
    ),
  );
}
