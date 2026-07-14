import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/loading_indicator.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  Color _getCategoryColor(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.salary:
        return const Color(0xFF4CAF50);
      case TransactionCategory.freelance:
        return const Color(0xFF8BC34A);
      case TransactionCategory.investment:
        return const Color(0xFF009688);
      case TransactionCategory.gift:
        return const Color(0xFFFFC107);
      case TransactionCategory.food:
        return const Color(0xFFFF5722);
      case TransactionCategory.shopping:
        return const Color(0xFFE91E63);
      case TransactionCategory.travel:
        return const Color(0xFF03A9F4);
      case TransactionCategory.bills:
        return const Color(0xFF9C27B0);
      case TransactionCategory.entertainment:
        return const Color(0xFF673AB7);
      case TransactionCategory.health:
        return const Color(0xFFF44336);
      case TransactionCategory.education:
        return const Color(0xFF3F51B5);
      case TransactionCategory.transfer:
        return const Color(0xFF795548);
      case TransactionCategory.other:
        return const Color(0xFF607D8B);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(analyticsDateProvider);
    final analyticsAsync = ref.watch(analyticsDataProvider);
    final monthStr = DateFormat('MMMM yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: Column(
        children: [
          // Date Selector Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    ref.read(analyticsDateProvider.notifier).previousMonth();
                  },
                ),
                Text(
                  monthStr,
                  style: AppTextStyles.h3,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () {
                    ref.read(analyticsDateProvider.notifier).nextMonth();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Main Scrollable Analytics Body
          Expanded(
            child: analyticsAsync.when(
              loading: () => const LoadingIndicator(),
              error: (err, stack) => Center(
                child: Text('Error loading analytics: $err'),
              ),
              data: (data) {
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Summary Row Cards
                    _buildSummaryStats(context, data),
                    VSpace.xl,

                    // Income vs Expense Comparison Bar Chart
                    _buildIncomeVsExpenseChart(context, data),
                    VSpace.xl,

                    // Category Breakdown Pie Chart
                    _buildCategoryBreakdownChart(context, data),
                    VSpace.xl,

                    // Historical Trends Line Chart
                    _buildTrendChart(context, data),
                    VSpace.xl,

                    // Key Insights Card
                    _buildInsightsCard(context, data),
                    VSpace.xl,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(BuildContext context, AnalyticsData data) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Income',
            amount: data.totalIncome,
            color: AppColors.income,
            icon: Icons.arrow_downward_rounded,
          ),
        ),
        HSpace.md,
        Expanded(
          child: _buildSummaryCard(
            title: 'Expenses',
            amount: data.totalExpense,
            color: AppColors.expense,
            icon: Icons.arrow_upward_rounded,
          ),
        ),
        HSpace.md,
        Expanded(
          child: _buildSummaryCard(
            title: 'Net Saved',
            amount: data.netSavings,
            color: data.netSavings >= 0 ? AppColors.income : AppColors.expense,
            icon: Icons.savings_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₹${amount.toStringAsFixed(0)}',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeVsExpenseChart(BuildContext context, AnalyticsData data) {
    final maxValue = data.totalIncome > data.totalExpense ? data.totalIncome : data.totalExpense;
    final yAxisInterval = maxValue > 0 ? (maxValue / 4) : 1000.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Income vs Expenses', style: AppTextStyles.h3),
            VSpace.lg,
            SizedBox(
              height: 200,
              child: data.totalIncome == 0 && data.totalExpense == 0
                  ? const Center(child: Text('No transaction data for this month'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceEvenly,
                        maxY: maxValue * 1.15,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45,
                              interval: yAxisInterval,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '₹${value.toStringAsFixed(0)}',
                                  style: AppTextStyles.caption.copyWith(fontSize: 8),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text('Income', style: AppTextStyles.caption),
                                    );
                                  case 1:
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text('Expenses', style: AppTextStyles.caption),
                                    );
                                  default:
                                    return const Text('');
                                }
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: data.totalIncome,
                                color: AppColors.income,
                                width: 30,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: data.totalExpense,
                                color: AppColors.expense,
                                width: 30,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownChart(BuildContext context, AnalyticsData data) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category Breakdown', style: AppTextStyles.h3),
            VSpace.lg,
            if (data.categoryBreakdown.isEmpty)
              const SizedBox(
                height: 150,
                child: Center(child: Text('No expense transactions recorded')),
              )
            else ...[
              SizedBox(
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: data.categoryBreakdown.map((item) {
                      return PieChartSectionData(
                        color: _getCategoryColor(item.category),
                        value: item.amount,
                        title: '${(item.percentage * 100).toStringAsFixed(0)}%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              VSpace.lg,
              // Legend list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.categoryBreakdown.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = data.categoryBreakdown[index];
                  final catName = item.category.name[0].toUpperCase() + item.category.name.substring(1);
                  final pctText = (item.percentage * 100).toStringAsFixed(1);

                  return Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(item.category),
                          shape: BoxShape.circle,
                        ),
                      ),
                      HSpace.md,
                      Expanded(
                        child: Text(
                          catName,
                          style: AppTextStyles.caption.copyWith(color: AppColors.primaryText),
                        ),
                      ),
                      Text(
                        '₹${item.amount.toStringAsFixed(0)} ($pctText%)',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, AnalyticsData data) {
    // Determine maximum historical limit
    double maxVal = 1000.0;
    for (final item in data.monthlyTrends) {
      if (item.income > maxVal) maxVal = item.income;
      if (item.expense > maxVal) maxVal = item.expense;
    }
    final yInterval = maxVal / 4;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Trend (Last 6 Months)', style: AppTextStyles.h3),
            VSpace.lg,
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${value.toStringAsFixed(0)}',
                            style: AppTextStyles.caption.copyWith(fontSize: 8),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < data.monthlyTrends.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data.monthlyTrends[idx].label,
                                style: AppTextStyles.caption.copyWith(fontSize: 8),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    // Income Line (Green)
                    LineChartBarData(
                      spots: data.monthlyTrends.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.income);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.income,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                    // Expense Line (Red)
                    LineChartBarData(
                      spots: data.monthlyTrends.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.expense);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.expense,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            VSpace.md,
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTrendLegend('Income', AppColors.income),
                HSpace.lg,
                _buildTrendLegend('Expenses', AppColors.expense),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 3, color: color),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildInsightsCard(BuildContext context, AnalyticsData data) {
    String highestCategoryText = 'None';
    if (data.highestSpendingCategory != null) {
      final name = data.highestSpendingCategory!.name;
      highestCategoryText = name[0].toUpperCase() + name.substring(1);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spending Insights', style: AppTextStyles.h3),
            VSpace.md,
            _buildInsightItem(
              icon: Icons.trending_up_rounded,
              title: 'Highest Spending Category',
              subtitle: highestCategoryText,
              value: '₹${data.highestSpendingAmount.toStringAsFixed(0)}',
              color: AppColors.expense,
            ),
            VSpace.md,
            const Divider(color: AppColors.border, height: 1),
            VSpace.md,
            _buildInsightItem(
              icon: Icons.query_builder_rounded,
              title: 'Average Daily Spending',
              subtitle: 'Based on elapsed days this month',
              value: '₹${data.averageDailySpending.toStringAsFixed(0)}',
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 18),
        ),
        HSpace.md,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
