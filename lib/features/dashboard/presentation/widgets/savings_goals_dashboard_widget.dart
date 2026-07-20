import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/skeleton_loader.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../savings_goal/presentation/providers/savings_goal_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class SavingsGoalsDashboardWidget extends ConsumerWidget {
  const SavingsGoalsDashboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);
    final currency = ref.watch(preferencesProvider).currency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return goalsAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 120, height: 20),
          VSpace.sm,
          const SkeletonLoader.card(height: 125),
        ],
      ),
      error: (err, stack) => Text('Error loading goals: $err'),
      data: (goals) {
        if (goals.isEmpty) {
          return InkWell(
            onTap: () => context.push('/savings-goals'),
            borderRadius: AppRadius.large,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : Colors.white,
                borderRadius: AppRadius.large,
                border: Border.all(color: isDark ? AppColors.border : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Savings Goals',
                        style: AppTextStyles.h3,
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.secondaryText),
                    ],
                  ),
                  VSpace.sm,
                  Text(
                    'Build healthy savings habits. Set your first goal today!',
                    style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Savings Goals',
                  style: AppTextStyles.h3,
                ),
                TextButton(
                  onPressed: () => context.push('/savings-goals'),
                  child: const Text('See All'),
                ),
              ],
            ),
            VSpace.sm,
            SizedBox(
              height: 125,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: goals.length > 5 ? 5 : goals.length,
                separatorBuilder: (context, index) => HSpace.md,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final pct = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0.0;
                  final pctText = (pct * 100).toStringAsFixed(0);
                  final targetDateStr = DateFormat('MMM yyyy').format(goal.targetDate);

                  return InkWell(
                    onTap: () => context.push('/add-savings-goal', extra: goal),
                    borderRadius: AppRadius.medium,
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surface : Colors.white,
                        borderRadius: AppRadius.medium,
                        border: Border.all(color: isDark ? AppColors.border : const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            goal.name,
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$currency${goal.currentAmount.toStringAsFixed(0)} / $currency${goal.targetAmount.toStringAsFixed(0)}',
                                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '$pctText%',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: AppRadius.small,
                                child: LinearProgressIndicator(
                                  value: pct > 1.0 ? 1.0 : pct,
                                  backgroundColor: isDark ? AppColors.border : const Color(0xFFE2E8F0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Target: $targetDateStr',
                            style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
