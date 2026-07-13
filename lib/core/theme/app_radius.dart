import 'package:flutter/material.dart';

/// Standard border radius used across the app.
/// Never use BorderRadius.circular() directly in widgets.
class AppRadius {
  const AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;

  static const BorderRadius small = BorderRadius.all(
    Radius.circular(sm),
  );

  static const BorderRadius medium = BorderRadius.all(
    Radius.circular(md),
  );

  static const BorderRadius large = BorderRadius.all(
    Radius.circular(lg),
  );

  static const BorderRadius extraLarge = BorderRadius.all(
    Radius.circular(xl),
  );
}