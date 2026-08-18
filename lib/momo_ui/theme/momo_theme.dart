import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'momo_colors.dart';
import 'momo_typography.dart';

/// MOMO UI — Theme Configuration.
///
/// Builds a complete Material 3 ThemeData from MOMO's design tokens.
/// Per MINDUSAGE.md: soft, cinematic, tactile, emotionally warm, futuristic.
class MomoTheme {
  MomoTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MomoColors.background,

        // Color scheme
        colorScheme: const ColorScheme.dark(
          primary: MomoColors.primary,
          onPrimary: MomoColors.background,
          secondary: MomoColors.accent,
          onSecondary: MomoColors.background,
          surface: MomoColors.surface,
          onSurface: MomoColors.textPrimary,
          error: MomoColors.error,
          onError: Colors.white,
        ),

        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: MomoTypography.displaySmall.copyWith(
            color: MomoColors.textPrimary,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          iconTheme: const IconThemeData(color: MomoColors.textPrimary),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: MomoColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MomoColors.primary,
            foregroundColor: MomoColors.background,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: MomoTypography.labelLarge,
          ),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MomoColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MomoColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: MomoTypography.bodyMedium.copyWith(
            color: MomoColors.textMuted,
          ),
        ),

        // Bottom navigation
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: MomoColors.surface,
          selectedItemColor: MomoColors.primary,
          unselectedItemColor: MomoColors.textMuted,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),

        // Text theme
        textTheme: TextTheme(
          displayLarge: MomoTypography.displayLarge,
          displayMedium: MomoTypography.displayMedium,
          displaySmall: MomoTypography.displaySmall,
          bodyLarge: MomoTypography.bodyLarge,
          bodyMedium: MomoTypography.bodyMedium,
          bodySmall: MomoTypography.bodySmall,
          labelLarge: MomoTypography.labelLarge,
          labelMedium: MomoTypography.labelMedium,
          labelSmall: MomoTypography.labelSmall,
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: MomoColors.surfaceLight,
          thickness: 1,
        ),
      );
}
