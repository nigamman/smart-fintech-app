import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/skeleton_loader.dart';
import '../../../../commons/widgets/transaction_title.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../savings_goal/presentation/providers/savings_goal_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../presentation/providers/dashboard_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/greeting_header.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  int _calculateHealthScore({
    required double totalBalance,
    required bool isBudgetExceeded,
    required bool isBudgetWarning,
    required int activeGoals,
    required int alertRenewals,
  }) {
    int score = 100;
    if (isBudgetExceeded) score -= 30;
    else if (isBudgetWarning) score -= 15;

    if (totalBalance < 0) score -= 20;
    if (activeGoals == 0) score -= 10;

    score -= (alertRenewals * 5);
    if (score < 10) score = 10;
    return score;
  }

  String _getHealthRating(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Action Needed';
  }

  Color _getHealthColor(int score) {
    if (score >= 85) return AppColors.income;
    if (score >= 70) return Colors.blueAccent;
    if (score >= 50) return AppColors.warning;
    return AppColors.expense;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);
    final subsAsync = ref.watch(subscriptionsStreamProvider);
    final budgetProgressAsync = ref.watch(budgetProgressProvider);
    final currency = ref.watch(preferencesProvider).currency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 140, height: 24),
                VSpace.lg,
                const SkeletonLoader.card(height: 180),
                VSpace.lg,
                const SkeletonLoader.card(height: 100),
                VSpace.lg,
                const SkeletonLoader.card(height: 120),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Text('Error loading dashboard: $error'),
          ),
          data: (dashboardData) {
            // Compute alerts list
            final List<Map<String, dynamic>> attentionAlerts = [];

            // Budget alert
            budgetProgressAsync.whenData((progress) {
              if (progress.totalLimit > 0) {
                if (progress.isExceeded) {
                  attentionAlerts.add({
                    'text': 'Budget limit exceeded! Spent ${progress.progressPercentage.toStringAsFixed(0)}% of limit.',
                    'color': AppColors.expense,
                    'icon': Icons.warning_rounded,
                  });
                } else if (progress.isWarning80) {
                  attentionAlerts.add({
                    'text': 'You have used ${pctText(progress.progressPercentage)}% of your monthly budget.',
                    'color': AppColors.warning,
                    'icon': Icons.info_outline_rounded,
                  });
                }
              }
            });

            // Subscription renewal alert
            subsAsync.whenData((subs) {
              final closeRenewals = subs.where((sub) {
                final days = sub.nextBillingDate.difference(DateTime.now()).inDays;
                return days >= 0 && days <= 2;
              });
              for (final sub in closeRenewals) {
                final days = sub.nextBillingDate.difference(DateTime.now()).inDays;
                final dayStr = days == 0 ? 'today' : (days == 1 ? 'tomorrow' : 'in $days days');
                attentionAlerts.add({
                  'text': '${sub.name} renews $dayStr ($currency${sub.amount.toStringAsFixed(0)}).',
                  'color': Colors.blueAccent,
                  'icon': Icons.alarm_rounded,
                });
              }
            });

            // Goals alert
            goalsAsync.whenData((goals) {
              for (final goal in goals) {
                if (goal.currentAmount < goal.targetAmount && goal.currentAmount / goal.targetAmount < 0.5) {
                  final remaining = goal.targetAmount - goal.currentAmount;
                  attentionAlerts.add({
                    'text': 'Goal "${goal.name}" needs $currency${remaining.toStringAsFixed(0)} to complete.',
                    'color': AppColors.accent,
                    'icon': Icons.flag_rounded,
                  });
                }
              }
            });

            // Compute Health Score
            final score = _calculateHealthScore(
              totalBalance: dashboardData.totalBalance,
              isBudgetExceeded: budgetProgressAsync.maybeWhen(
                data: (progress) => progress.isExceeded,
                orElse: () => false,
              ),
              isBudgetWarning: budgetProgressAsync.maybeWhen(
                data: (progress) => progress.isWarning80,
                orElse: () => false,
              ),
              activeGoals: goalsAsync.maybeWhen(
                data: (goals) => goals.length,
                orElse: () => 0,
              ),
              alertRenewals: attentionAlerts.where((a) => a['icon'] == Icons.alarm_rounded).length,
            );

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(dashboardDataProvider);
                ref.invalidate(savingsGoalsStreamProvider);
                ref.invalidate(subscriptionsStreamProvider);
                ref.invalidate(budgetProgressProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GreetingHeader(userName: dashboardData.userName),
                    VSpace.xl,

                    // Safe to Spend Card
                    BalanceCard(
                      safeToSpend: dashboardData.safeToSpend,
                      totalBalance: dashboardData.totalBalance,
                      monthlyIncome: dashboardData.monthlyIncome,
                      totalExpense: dashboardData.totalExpense,
                    ),
                    VSpace.xl,

                    // Financial Health Score
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131B2E) : Colors.white,
                        borderRadius: AppRadius.large,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: CircularProgressIndicator(
                                  value: score / 100.0,
                                  strokeWidth: 6,
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  valueColor: AlwaysStoppedAnimation<Color>(_getHealthColor(score)),
                                ),
                              ),
                              Text(
                                score.toString(),
                                style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          HSpace.lg,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Financial Health Score',
                                  style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                                ),
                                VSpace.xs,
                                Text(
                                  _getHealthRating(score),
                                  style: AppTextStyles.h3.copyWith(
                                    color: _getHealthColor(score),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                VSpace.xs,
                                Text(
                                  score >= 85
                                      ? 'Excellent control of budget and savings.'
                                      : 'Review warnings below to improve your score.',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    VSpace.xl,

                    // Things requiring attention (Updates Inbox)
                    if (attentionAlerts.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Things that need attention',
                            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      VSpace.md,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131B2E) : Colors.white,
                          borderRadius: AppRadius.large,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: attentionAlerts.map((alert) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(alert['icon'] as IconData, color: alert['color'] as Color, size: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      alert['text'] as String,
                                      style: AppTextStyles.bodySecondary.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      VSpace.xl,
                    ],

                    // Today's Activity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Activity",
                          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    VSpace.md,
                    if (dashboardData.recentTransactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131B2E) : Colors.white,
                          borderRadius: AppRadius.large,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          'No transactions recorded today.',
                          style: AppTextStyles.bodySecondary,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF131B2E) : Colors.white,
                          borderRadius: AppRadius.large,
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: dashboardData.recentTransactions.take(3).map((tx) {
                            return TransactionTile(
                              title: tx.note ?? tx.category.name,
                              category: tx.category.name,
                              amount: tx.amount,
                              date: tx.transactionDate,
                              type: tx.type,
                            );
                          }).toList(),
                        ),
                      ),
                    VSpace.xl,

                    // Savings Goals Progress Summary
                    goalsAsync.maybeWhen(
                      data: (goals) {
                        if (goals.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Savings Goals Progress',
                              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold),
                            ),
                            VSpace.md,
                            ...goals.take(2).map((goal) {
                              final pct = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0.0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF131B2E) : Colors.white,
                                  borderRadius: AppRadius.large,
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(goal.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                                        Text(
                                          '${(pct * 100).toStringAsFixed(0)}%',
                                          style: AppTextStyles.caption.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    VSpace.sm,
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct > 1.0 ? 1.0 : pct,
                                        minHeight: 5,
                                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            VSpace.xl,
                          ],
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String pctText(double pct) => (pct * 100).toStringAsFixed(0);
}
