import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/loading_indicator.dart';
import '../../../../commons/widgets/primary_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/savings_goal.dart';
import '../providers/savings_goal_providers.dart';
import '../../../../commons/widgets/skeleton_loader.dart';

class SavingsGoalListScreen extends ConsumerWidget {
  const SavingsGoalListScreen({super.key});

  void _showAddMoneyDialog(BuildContext context, WidgetRef ref, SavingsGoal goal) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Money to "${goal.name}"'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current Saved: ₹${goal.currentAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                ),
                VSpace.md,
                TextFormField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount to Add',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter an amount';
                    final numVal = double.tryParse(val);
                    if (numVal == null || numVal <= 0) return 'Please enter a valid positive amount';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final addedAmount = double.parse(amountController.text);
                final updatedGoal = SavingsGoal(
                  id: goal.id,
                  userId: goal.userId,
                  name: goal.name,
                  targetAmount: goal.targetAmount,
                  currentAmount: goal.currentAmount + addedAmount,
                  targetDate: goal.targetDate,
                  createdAt: goal.createdAt,
                );

                Navigator.pop(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(savingsGoalControllerProvider.notifier).saveGoal(updatedGoal);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Deposited ₹${addedAmount.toStringAsFixed(0)} successfully!')),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error adding money: $e')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
      ),
      body: goalsAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SkeletonLoader.card(height: 140),
            VSpace.md,
            const SkeletonLoader.card(height: 140),
            VSpace.md,
            const SkeletonLoader.card(height: 140),
          ],
        ),
        error: (err, stack) => Center(
          child: Text('Error loading savings goals: $err'),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(savingsGoalsStreamProvider);
              },
              child: Stack(
                children: [
                  ListView(), // Scrollable background to trigger refresh
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            size: 64,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                          VSpace.lg,
                          Text(
                            'No savings goals set yet',
                            style: AppTextStyles.h3,
                          ),
                          VSpace.sm,
                          Text(
                            'Define targets for big purchases, emergencies, or investments.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
                          ),
                          VSpace.xl,
                          PrimaryButton(
                            text: 'Create savings goal',
                            onPressed: () => context.push('/add-savings-goal'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(savingsGoalsStreamProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: goals.length,
              separatorBuilder: (context, index) => VSpace.md,
              itemBuilder: (context, index) {
                final goal = goals[index];
                final pct = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0.0;
                final pctText = (pct * 100).toStringAsFixed(0);
                final targetDateStr = DateFormat('dd MMMM yyyy').format(goal.targetDate);

                // Calculate remaining days
                final daysRemaining = goal.targetDate.difference(DateTime.now()).inDays;
                String timeRemainingText = '';
                if (daysRemaining > 30) {
                  final months = (daysRemaining / 30).floor();
                  timeRemainingText = '$months ${months == 1 ? 'month' : 'months'} left';
                } else if (daysRemaining > 0) {
                  timeRemainingText = '$daysRemaining ${daysRemaining == 1 ? 'day' : 'days'} left';
                } else {
                  timeRemainingText = 'Target date reached';
                }

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.large,
                    side: const BorderSide(color: AppColors.border),
                  ),
                  color: AppColors.surface,
                  child: InkWell(
                    onTap: () => context.push('/add-savings-goal', extra: goal),
                    borderRadius: AppRadius.large,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  goal.name,
                                  style: AppTextStyles.h3,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: AppRadius.small,
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  '$pctText%',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          VSpace.md,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saved So Far',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${goal.currentAmount.toStringAsFixed(0)}',
                                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Target Amount',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${goal.targetAmount.toStringAsFixed(0)}',
                                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
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
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              minHeight: 8,
                            ),
                          ),
                          VSpace.md,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Target Date: $targetDateStr',
                                style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                              ),
                              Text(
                                timeRemainingText,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: daysRemaining > 0 ? AppColors.income : AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                          VSpace.md,
                          const Divider(color: AppColors.border, height: 1),
                          VSpace.sm,
                          Center(
                            child: TextButton.icon(
                              onPressed: () => _showAddMoneyDialog(context, ref, goal),
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              label: const Text('Add Money'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-savings-goal'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
