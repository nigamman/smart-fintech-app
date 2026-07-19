import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/loading_indicator.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/budget_providers.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.salary:
        return Icons.account_balance_wallet_rounded;
      case TransactionCategory.freelance:
        return Icons.work_outline_rounded;
      case TransactionCategory.investment:
        return Icons.trending_up_rounded;
      case TransactionCategory.gift:
        return Icons.card_giftcard_rounded;
      case TransactionCategory.food:
        return Icons.restaurant_rounded;
      case TransactionCategory.shopping:
        return Icons.shopping_bag_rounded;
      case TransactionCategory.travel:
        return Icons.directions_car_rounded;
      case TransactionCategory.bills:
        return Icons.receipt_long_rounded;
      case TransactionCategory.entertainment:
        return Icons.movie_creation_outlined;
      case TransactionCategory.health:
        return Icons.medical_services_outlined;
      case TransactionCategory.education:
        return Icons.school_rounded;
      case TransactionCategory.transfer:
        return Icons.swap_horiz_rounded;
      case TransactionCategory.other:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(budgetProgressProvider);
    final now = DateTime.now();
    final monthStr = DateFormat('MMMM yyyy').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: progressAsync.when(
        loading: () => const LoadingIndicator(),
        error: (err, stack) => Center(
          child: Text('Error loading budgets: $err'),
        ),
        data: (progress) {
          final isNoLimitSet = progress.totalLimit == 0;
          final pct = progress.progressPercentage;
          final pctText = (pct * 100).toStringAsFixed(0);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(budgetsStreamProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Month Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthStr,
                      style: AppTextStyles.h2,
                    ),
                    Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.primary.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ],
                ),
                VSpace.lg,

                // Warning / Alert Banners
                if (!isNoLimitSet) ...[
                  if (progress.isExceeded)
                    _buildAlertBanner(
                      context,
                      '🚨 Budget Exceeded!',
                      'You have spent ₹${progress.totalSpent.toStringAsFixed(0)} which exceeds your overall budget limit of ₹${progress.totalLimit.toStringAsFixed(0)} by ₹${(progress.totalSpent - progress.totalLimit).toStringAsFixed(0)}.',
                      AppColors.expense,
                    )
                  else if (progress.isWarning80)
                    _buildAlertBanner(
                      context,
                      '⚠️ Warning: Near Budget Limit',
                      'You have spent $pctText% of your monthly budget limit. Please spend cautiously.',
                      Colors.orange,
                    ),
                ],

                // Overall Monthly Budget Card
                Card(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Monthly Budget',
                              style: AppTextStyles.h3,
                            ),
                          ],
                        ),
                        VSpace.md,
                        if (isNoLimitSet) ...[
                          Text(
                            'No monthly budget limit set yet. Set your income in the Settings tab to calculate.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ] else ...[
                          // Remaining details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Spent',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${progress.totalSpent.toStringAsFixed(0)}',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Remaining',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${progress.remaining.toStringAsFixed(0)}',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: progress.remaining >= 0
                                          ? AppColors.income
                                          : AppColors.expense,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          VSpace.md,
                          // Progress Bar
                          ClipRRect(
                            borderRadius: AppRadius.small,
                            child: LinearProgressIndicator(
                              value: pct > 1.0 ? 1.0 : pct,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pct >= 1.0
                                    ? AppColors.expense
                                    : pct >= 0.8
                                        ? Colors.orange
                                        : AppColors.primary,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$pctText% spent of ₹${progress.totalLimit.toStringAsFixed(0)}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                VSpace.xl,

                // Category Budgets Header
                Text(
                  'Category Budgets',
                  style: AppTextStyles.h3,
                ),
                VSpace.sm,

                if (progress.categoryProgresses.isEmpty) ...[
                  VSpace.lg,
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: AppColors.secondaryText.withValues(alpha: 0.5),
                        ),
                        VSpace.md,
                        Text(
                          'No category-specific budgets set yet.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // List of Category Budgets
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: progress.categoryProgresses.length,
                    separatorBuilder: (context, index) => VSpace.md,
                    itemBuilder: (context, index) {
                      final catProg = progress.categoryProgresses[index];
                      final catPct = catProg.progressPercentage;
                      final category = catProg.category;
                      final categoryName =
                          category.name[0].toUpperCase() + category.name.substring(1);

                      // Find full budget entity to pass to edit screen
                      final budgets = ref.read(budgetsStreamProvider).value ?? [];
                      final budgetEntity = budgets.firstWhere((b) => b.id == catProg.budgetId);

                      return InkWell(
                        onTap: () {
                          context.push('/add-budget', extra: budgetEntity);
                        },
                        borderRadius: AppRadius.medium,
                        child: Container(
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
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: Icon(
                                      _getCategoryIcon(category),
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  HSpace.md,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          categoryName,
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${catProg.spent.toStringAsFixed(0)} spent of ₹${catProg.limit.toStringAsFixed(0)}',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildCategoryBadge(catProg),
                                ],
                              ),
                              VSpace.md,
                              ClipRRect(
                                borderRadius: AppRadius.small,
                                child: LinearProgressIndicator(
                                  value: catPct > 1.0 ? 1.0 : catPct,
                                  backgroundColor: AppColors.border,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    catProg.isExceeded
                                        ? AppColors.expense
                                        : catProg.isWarning80
                                            ? Colors.orange
                                            : AppColors.income,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-budget'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildAlertBanner(
    BuildContext context,
    String title,
    String message,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(CategoryBudgetProgress progress) {
    Color color = AppColors.income;
    String text = 'Safe';

    if (progress.isExceeded) {
      color = AppColors.expense;
      text = 'Exceeded';
    } else if (progress.isWarning80) {
      color = Colors.orange;
      text = 'Near Limit';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.small,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
