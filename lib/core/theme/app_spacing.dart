import 'package:gap/gap.dart';

/// 8-point spacing system.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Vertical Gaps
class VSpace {
  const VSpace._();

  static const Gap xs = Gap(AppSpacing.xs);
  static const Gap sm = Gap(AppSpacing.sm);
  static const Gap md = Gap(AppSpacing.md);
  static const Gap lg = Gap(AppSpacing.lg);
  static const Gap xl = Gap(AppSpacing.xl);
  static const Gap xxl = Gap(AppSpacing.xxl);
}

/// Horizontal Gaps
class HSpace {
  const HSpace._();

  static const Gap xs = Gap(AppSpacing.xs);
  static const Gap sm = Gap(AppSpacing.sm);
  static const Gap md = Gap(AppSpacing.md);
  static const Gap lg = Gap(AppSpacing.lg);
  static const Gap xl = Gap(AppSpacing.xl);
  static const Gap xxl = Gap(AppSpacing.xxl);
}