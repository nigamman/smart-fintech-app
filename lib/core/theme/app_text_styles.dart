import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get display => GoogleFonts.fraunces(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static TextStyle get h1 => GoogleFonts.fraunces(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static TextStyle get h2 => GoogleFonts.fraunces(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static TextStyle get h3 => GoogleFonts.fraunces(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static TextStyle get title => GoogleFonts.fraunces(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );

  static TextStyle get bodySecondary => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
  );

  static TextStyle get button => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryDark,
  );

  // Tabulated Mono figures style
  static TextStyle get mono => GoogleFonts.spaceMono(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static TextStyle get monoSecondary => GoogleFonts.spaceMono(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
  );
}