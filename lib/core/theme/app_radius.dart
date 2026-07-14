import 'package:flutter/material.dart';

class AppRadius {
  const AppRadius._();

  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;

  static const BorderRadius small =
  BorderRadius.all(Radius.circular(sm));

  static const BorderRadius medium =
  BorderRadius.all(Radius.circular(md));

  static const BorderRadius large =
  BorderRadius.all(Radius.circular(lg));

  static const BorderRadius extraLarge =
  BorderRadius.all(Radius.circular(xl));
}