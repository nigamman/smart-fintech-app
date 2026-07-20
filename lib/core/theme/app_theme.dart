import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.primaryText,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        titleTextStyle: AppTextStyles.title.copyWith(color: AppColors.primaryText),
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: AppColors.primaryText),
        headlineLarge: AppTextStyles.h1.copyWith(color: AppColors.primaryText),
        headlineMedium: AppTextStyles.h2.copyWith(color: AppColors.primaryText),
        headlineSmall: AppTextStyles.h3.copyWith(color: AppColors.primaryText),
        titleLarge: AppTextStyles.title.copyWith(color: AppColors.primaryText),
        bodyLarge: AppTextStyles.body.copyWith(color: AppColors.primaryText),
        bodyMedium: AppTextStyles.bodySecondary.copyWith(color: AppColors.secondaryText),
        bodySmall: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.label.copyWith(color: AppColors.secondaryText),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: const BorderSide(color: AppColors.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
          textStyle: AppTextStyles.button,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppColors.secondaryText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkBg = Color(0xFF090D16);
    const darkCard = Color(0xFF131B2E);
    const darkBorder = Color(0xFF1E293B);
    const darkPrimaryText = Color(0xFFF1F5F9);
    const darkSecondaryText = Color(0xFF94A3B8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
        primary: AppColors.accent,
        onPrimary: AppColors.primary,
        secondary: AppColors.accent,
        surface: darkCard,
        onSurface: darkPrimaryText,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: darkBg,
        foregroundColor: darkPrimaryText,
        titleTextStyle: AppTextStyles.title.copyWith(color: darkPrimaryText),
        iconTheme: const IconThemeData(color: darkPrimaryText),
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: darkPrimaryText),
        headlineLarge: AppTextStyles.h1.copyWith(color: darkPrimaryText),
        headlineMedium: AppTextStyles.h2.copyWith(color: darkPrimaryText),
        headlineSmall: AppTextStyles.h3.copyWith(color: darkPrimaryText),
        titleLarge: AppTextStyles.title.copyWith(color: darkPrimaryText),
        bodyLarge: AppTextStyles.body.copyWith(color: darkPrimaryText),
        bodyMedium: AppTextStyles.bodySecondary.copyWith(color: darkSecondaryText),
        bodySmall: AppTextStyles.caption.copyWith(color: darkSecondaryText),
        labelLarge: AppTextStyles.button.copyWith(color: AppColors.primary),
        labelMedium: AppTextStyles.label.copyWith(color: darkSecondaryText),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: const BorderSide(color: AppColors.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.primary,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
        ),
      ),

      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: const BorderSide(color: darkBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1.0),
        ),
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkPrimaryText,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: darkSecondaryText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
