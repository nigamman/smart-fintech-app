import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/bouncy_button.dart';
import '../../../../commons/widgets/skeleton_loader.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../dashboard/presentation/screens/main_navigation_screen.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/analytics_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _chartAnimationController;

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.bills:
        return const Color(0xFFC8A05B); // Brass
      case TransactionCategory.food:
        return const Color(0xFFBC5B3E); // Rust Red
      case TransactionCategory.travel:
        return const Color(0xFF5E7A8A); // Steel Blue
      case TransactionCategory.shopping:
        return const Color(0xFF7C9473); // Sage Green
      case TransactionCategory.entertainment:
        return const Color(0xFF8A8EC4); // Lavender
      case TransactionCategory.health:
        return const Color(0xFFB86B7E); // Rose
      case TransactionCategory.education:
        return const Color(0xFFA4B86B); // Olive
      case TransactionCategory.salary:
        return const Color(0xFF7C9473); // Sage Green
      case TransactionCategory.freelance:
        return const Color(0xFFC8A05B); // Brass
      case TransactionCategory.investment:
        return const Color(0xFF5E7A8A); // Steel Blue
      case TransactionCategory.gift:
        return const Color(0xFF8A8EC4); // Lavender
      case TransactionCategory.transfer:
        return const Color(0xFF64748B); // Slate
      case TransactionCategory.other:
        return const Color(0xFF94A3B8); // Light Slate;
    }
  }

  String _formatCompact(double value, String currency) {
    if (value >= 1000) {
      return '$currency${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$currency${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainNavigationIndexProvider, (previous, next) {
      if (next == 2) {
        _chartAnimationController.forward(from: 0.0);
      } else {
        _chartAnimationController.reset();
      }
    });

    final analyticsAsync = ref.watch(analyticsDataProvider);
    final currency = ref.watch(preferencesProvider).currency;
    final userAsync = ref.watch(userProfileStreamProvider);

    final userInitials = userAsync.maybeWhen(
      data: (profile) {
        if (profile != null && profile.name.trim().isNotEmpty) {
          final parts = profile.name.trim().split(' ');
          if (parts.length >= 2) {
            return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
          }
          return parts[0][0].toUpperCase();
        }
        return 'U';
      },
      orElse: () => 'U',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: analyticsAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: const [
              SkeletonLoader.card(height: 80),
              VSpace.lg,
              SkeletonLoader.card(height: 100),
              VSpace.lg,
              SkeletonLoader.card(height: 200),
            ],
          ),
          error: (err, stack) => Center(
            child: Text('Error loading insights: $err', style: AppTextStyles.body),
          ),
          data: (data) {
            return AnimatedBuilder(
              animation: _chartAnimationController,
              builder: (context, child) {
                final double animValue = CurvedAnimation(
                  parent: _chartAnimationController,
                  curve: Curves.fastOutSlowIn,
                ).value;

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Top Custom Header Row (FT & R)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Gold App logo badge
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1.0,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.asset(
                              'assets/icons/icon-master-1024.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Profile avatar group
                        BouncyButton(
                          onTap: () => context.push('/settings'),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 1.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                userInitials,
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Title "Insights"
                    Text(
                      'Insights',
                      style: GoogleFonts.fraunces(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Ask the AI counsel row
                    GestureDetector(
                      onTap: () => context.push('/ai-counsel'),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 14,
                              color: AppColors.background,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ask the AI counsel',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Horizontal Triple metrics row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'INCOME',
                            data.totalIncome,
                            const Color(0xFF7C9473),
                            currency,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryCard(
                            'EXPENSES',
                            data.totalExpense,
                            const Color(0xFFBC5B3E),
                            currency,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryCard(
                            'NET SAVED',
                            data.netSavings,
                            const Color(0xFF7C9473),
                            currency,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Income vs Expenses double bar chart
                    _buildIncomeVsExpenseChart(data, currency, animValue),
                    const SizedBox(height: 20),

                    // Category breakdown donut chart
                    _buildCategoryDonutChart(data, currency, animValue),
                    const SizedBox(height: 20),

                    // Net Savings Trend line chart
                    _buildTrendChart(data, currency, animValue),
                    const SizedBox(height: 20),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double val, Color valColor, String currency) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.disabledText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatCompact(val, currency),
            style: AppTextStyles.mono.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeVsExpenseChart(AnalyticsData data, String currency, double animValue) {
    if (data.monthlyTrends.isEmpty) return const SizedBox.shrink();

    double maxVal = 1000.0;
    for (final item in data.monthlyTrends) {
      if (item.income > maxVal) maxVal = item.income;
      if (item.expense > maxVal) maxVal = item.expense;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INCOME VS EXPENSES - LAST 6 MONTHS',
            style: AppTextStyles.label.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.disabledText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: maxVal * 1.15,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < data.monthlyTrends.length) {
                          final label = data.monthlyTrends[idx].label;
                          final displayLabel = label.length >= 3 ? label.substring(0, 3) : label;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              displayLabel,
                              style: AppTextStyles.caption.copyWith(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(data.monthlyTrends.length, (idx) {
                  final item = data.monthlyTrends[idx];
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: item.income * animValue,
                        color: const Color(0xFF7C9473), // Sage Green
                        width: 7,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                      BarChartRodData(
                        toY: item.expense * animValue,
                        color: const Color(0xFFBC5B3E), // Rust Red
                        width: 7,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(3),
                        ),
                      ),
                    ],
                    barsSpace: 3,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend row
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildSquareLegend('Income', const Color(0xFF7C9473)),
              const SizedBox(width: 16),
              _buildSquareLegend('Expenses', const Color(0xFFBC5B3E)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDonutChart(AnalyticsData data, String currency, double animValue) {
    if (data.categoryBreakdown.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Text('No category statistics this month', style: AppTextStyles.bodySecondary),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXPENSES BY CATEGORY',
            style: AppTextStyles.label.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.disabledText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut Chart on left
              SizedBox(
                width: 100,
                height: 100,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 28 * animValue,
                    sections: data.categoryBreakdown.map((item) {
                      return PieChartSectionData(
                        color: _getCategoryColor(item.category),
                        value: item.amount * animValue,
                        showTitle: false,
                        radius: 12 * animValue,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 28),

              // Legend column on right
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.categoryBreakdown.take(4).map((item) {
                    final catName = item.category.name[0].toUpperCase() + item.category.name.substring(1);
                    final pctText = (item.percentage * 100).toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(item.category),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$catName - $pctText%',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11,
                                color: AppColors.disabledText,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(AnalyticsData data, String currency, double animValue) {
    if (data.monthlyTrends.isEmpty) return const SizedBox.shrink();

    double maxSavings = 1000.0;
    double minSavings = -1000.0;
    for (final item in data.monthlyTrends) {
      if (item.savings > maxSavings) maxSavings = item.savings;
      if (item.savings < minSavings) minSavings = item.savings;
    }
    final spread = maxSavings - minSavings;
    final yInterval = spread > 0 ? (spread / 4) : 1000.0;

    String formatCompactSavings(double value) {
      final isNeg = value < 0;
      final absVal = value.abs();
      final sign = isNeg ? '-' : '';
      if (absVal >= 1000) {
        return '$sign$currency${(absVal / 1000).toStringAsFixed(0)}k';
      }
      return '$sign$currency${absVal.toStringAsFixed(0)}';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NET SAVINGS TREND',
            style: AppTextStyles.label.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.disabledText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withOpacity(0.15),
                    strokeWidth: 0.8,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            formatCompactSavings(value),
                            style: AppTextStyles.caption.copyWith(fontSize: 8.5),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < data.monthlyTrends.length) {
                          final label = data.monthlyTrends[idx].label;
                          final displayLabel = label.length >= 3 ? label.substring(0, 3) : label;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              displayLabel,
                              style: AppTextStyles.caption.copyWith(fontSize: 9),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.monthlyTrends.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.savings * animValue);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary, // Gold line
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            color: AppColors.disabledText,
          ),
        ),
      ],
    );
  }
}
