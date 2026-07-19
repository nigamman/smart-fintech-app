import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class BalanceCard extends ConsumerStatefulWidget {
  final double safeToSpend;
  final double totalBalance;
  final double monthlyIncome;
  final double totalExpense;
  final int healthScore;

  const BalanceCard({
    super.key,
    required this.safeToSpend,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.totalExpense,
    this.healthScore = 100,
  });

  @override
  ConsumerState<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<BalanceCard> with SingleTickerProviderStateMixin {
  late final AnimationController _arcController;
  late Animation<double> _arcProgressAnimation;
  late double _targetPct;
  late double _limit;

  @override
  void initState() {
    super.initState();
    _arcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _limit = widget.monthlyIncome > 0 ? (widget.monthlyIncome / 30.0) : 2000.0;
    _targetPct = (_limit > 0 ? (widget.safeToSpend / _limit) : 0.5).clamp(0.0, 1.0);

    // Sequence: 0.0 -> 1.0 (Full) -> Target Pct (Settle)
    _arcProgressAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: _targetPct).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
    ]).animate(_arcController);

    _arcController.forward();
  }

  @override
  void dispose() {
    _arcController.dispose();
    super.dispose();
  }

  void _showSafeToSpendInfoDialog(BuildContext context, WidgetRef ref) {
    final currency = ref.read(preferencesProvider).currency;
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final remainingDays = (lastDay - now.day) + 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Safe to Spend Today',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Calculated as:',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '(Monthly Income - Monthly Expenses)\n÷\nRemaining Days in Month',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your current calculation:',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildCalcRow('Monthly Income:', '$currency${widget.monthlyIncome.toStringAsFixed(0)}'),
              const SizedBox(height: 6),
              _buildCalcRow('Monthly Expenses:', '- $currency${widget.totalExpense.toStringAsFixed(0)}', isNegative: true),
              const Divider(height: 16, color: AppColors.border),
              _buildCalcRow('Remaining Budget:', '$currency${(widget.monthlyIncome - widget.totalExpense).toStringAsFixed(0)}', isBold: true),
              const SizedBox(height: 6),
              _buildCalcRow('Remaining Days:', '$remainingDays days left'),
              const Divider(height: 16, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Safe to Spend Today:', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    '$currency${widget.safeToSpend.toStringAsFixed(0)}',
                    style: AppTextStyles.mono.copyWith(
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'This helps you pace your spending so you don\'t run out of money before the month ends.',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, {bool isNegative = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12)),
        Text(
          value,
          style: isBold
              ? AppTextStyles.mono.copyWith(fontSize: 12)
              : AppTextStyles.monoSecondary.copyWith(
                  fontSize: 12,
                  color: isNegative ? AppColors.expense : null,
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(preferencesProvider).currency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final netSavings = widget.monthlyIncome - widget.totalExpense;
    final netSign = netSavings >= 0 ? '+' : '-';
    final formattedNet = '$netSign$currency${netSavings.abs().toStringAsFixed(0)}';

    return GestureDetector(
      onTap: () => _showSafeToSpendInfoDialog(context, ref),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: CustomPaint(
          painter: LedgerBackgroundPainter(
            lineColor: AppColors.border.withOpacity(0.35),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: _arcProgressAnimation,
              builder: (context, child) {
                // Calculate display safe to spend based on active animated factor
                final currentProgress = _arcProgressAnimation.value;
                final displaySafeToSpend = widget.safeToSpend > 0
                    ? (widget.safeToSpend * (currentProgress / _targetPct))
                    : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Arc Gauge CustomPaint with Animated Value
                    SizedBox(
                      width: 220,
                      height: 110,
                      child: CustomPaint(
                        painter: SafeToSpendArcPainter(
                          progressPct: currentProgress,
                          activeColor: AppColors.primary,
                          isDark: isDark,
                        ),
                      ),
                    ),
                    
                    Text(
                      'SAFE TO SPEND TODAY',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Large Serif Amount (Fraunces)
                    Text(
                      '$currency${displaySafeToSpend.toStringAsFixed(0)}',
                      style: GoogleFonts.fraunces(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle: Health Score • On Pace
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Health score ${widget.healthScore}',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.circle, size: 4, color: AppColors.secondaryText),
                        const SizedBox(width: 6),
                        Text(
                          widget.safeToSpend > 0 ? 'on pace' : 'budget deficit',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            color: widget.safeToSpend > 0 ? AppColors.income : AppColors.expense,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Bottom columns divider
                    Container(
                      height: 0.5,
                      color: AppColors.border,
                    ),
                    const SizedBox(height: 16),

                    // Bottom cash details (Tabulated Mono numbers)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CASH BALANCE',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppColors.disabledText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$currency${widget.totalBalance.toStringAsFixed(0)}',
                                style: AppTextStyles.mono.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 0.5,
                          height: 32,
                          color: AppColors.border,
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'THIS MONTH',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppColors.disabledText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedNet,
                                style: AppTextStyles.mono.copyWith(
                                  fontSize: 15,
                                  color: netSavings >= 0 ? AppColors.income : AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SafeToSpendArcPainter extends CustomPainter {
  final double progressPct;
  final Color activeColor;
  final bool isDark;

  SafeToSpendArcPainter({
    required this.progressPct,
    required this.activeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 8);
    final radius = size.width / 2.2;

    // Track arc
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = isDark ? const Color(0xFF2C2D24) : const Color(0xFFE2E8F0);

    const startAngle = math.pi;
    const sweepAngle = math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active progress arc
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..color = activeColor;

    final activeSweepAngle = sweepAngle * progressPct;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweepAngle,
      false,
      activePaint,
    );

    // Draw track ticks on the outside edge
    final tickPaint = Paint()
      ..color = isDark ? const Color(0xFF3C3D32) : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;
    
    final tickRadiusOuter = radius + 6;
    final tickRadiusInner = radius + 2;

    for (int i = 0; i <= 6; i++) {
      final angle = startAngle + (sweepAngle * (i / 6.0));
      final x1 = center.dx + tickRadiusInner * math.cos(angle);
      final y1 = center.dy + tickRadiusInner * math.sin(angle);
      final x2 = center.dx + tickRadiusOuter * math.cos(angle);
      final y2 = center.dy + tickRadiusOuter * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LedgerBackgroundPainter extends CustomPainter {
  final Color lineColor;
  LedgerBackgroundPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    // Draw horizontal lines spaced 16px apart
    const double spacing = 16.0;
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
