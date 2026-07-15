import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../commons/widgets/primary_button.dart';
import '../../../../commons/widgets/skeleton_loader.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../savings_goal/domain/entities/savings_goal.dart';
import '../../../savings_goal/presentation/providers/savings_goal_providers.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  void _showGoalDetailsSheet(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
    String currency,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount)
        : 0.0;
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(
      0.0,
      double.infinity,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          goal.name,
                          style: AppTextStyles.h2.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.expense,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Goal?'),
                              content: Text(
                                'Are you sure you want to delete "${goal.name}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.expense,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(savingsGoalControllerProvider.notifier)
                                .deleteGoal(goal.id);
                            ref.invalidate(savingsGoalsStreamProvider);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                  VSpace.sm,
                  Text(
                    'Target Date: ${DateFormat('dd MMMM yyyy').format(goal.targetDate)}',
                    style: AppTextStyles.bodySecondary,
                  ),
                  VSpace.lg,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved: $currency${goal.currentAmount.toStringAsFixed(0)} / $currency${goal.targetAmount.toStringAsFixed(0)}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  VSpace.sm,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct > 1.0 ? 1.0 : pct,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                    ),
                  ),
                  VSpace.lg,
                  if (remaining > 0)
                    Text(
                      'Needs $currency${remaining.toStringAsFixed(0)} more to reach target.',
                      style: AppTextStyles.caption.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  VSpace.xl,
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showAddMoneyDialog(context, ref, goal, false),
                          icon: const Icon(Icons.remove),
                          label: const Text('Withdraw'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.expense,
                            side: const BorderSide(color: AppColors.expense),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showAddMoneyDialog(context, ref, goal, true),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Cash'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: isDark
                                ? const Color(0xFF020617)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddMoneyDialog(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
    bool isAdding,
  ) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isAdding
                ? 'Add money to "${goal.name}"'
                : 'Withdraw from "${goal.name}"',
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: const Icon(Icons.currency_rupee_rounded),
                helperText: !isAdding
                    ? 'Available: ${goal.currentAmount.toStringAsFixed(0)}'
                    : null,
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter an amount';
                final amount = double.tryParse(val);
                if (amount == null || amount <= 0)
                  return 'Please enter a valid positive amount';
                if (!isAdding && amount > goal.currentAmount)
                  return 'Insufficient goal funds';
                return null;
              },
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
                final amount = double.parse(controller.text);
                final change = isAdding ? amount : -amount;

                final updated = SavingsGoal(
                  id: goal.id,
                  userId: goal.userId,
                  name: goal.name,
                  targetAmount: goal.targetAmount,
                  currentAmount: (goal.currentAmount + change).clamp(
                    0,
                    double.infinity,
                  ),
                  targetDate: goal.targetDate,
                  createdAt: goal.createdAt,
                );

                await ref
                    .read(savingsGoalControllerProvider.notifier)
                    .saveGoal(updated);
                ref.invalidate(savingsGoalsStreamProvider);

                Navigator.pop(context); // Close dialog
                Navigator.pop(
                  context,
                ); // Close bottom sheet to refresh progress
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showBillActionsSheet(
    BuildContext context,
    WidgetRef ref,
    Subscription sub,
    String currency,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  sub.name,
                  style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                ),
                VSpace.sm,
                Text(
                  'Amount: $currency${sub.amount.toStringAsFixed(0)} • Billing: ${sub.billingCycle.name.toUpperCase()}',
                  style: AppTextStyles.bodySecondary,
                ),
                Text(
                  'Next Due Date: ${DateFormat('dd MMMM yyyy').format(sub.nextBillingDate)}',
                  style: AppTextStyles.caption,
                ),
                VSpace.xl,
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.edit_rounded, color: Colors.white),
                  ),
                  title: const Text('Edit Bill Details'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/add-subscription', extra: sub);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.expense,
                    child: Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  title: const Text('Delete Bill / Sub'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Bill?'),
                        content: Text(
                          'Are you sure you want to stop tracking "${sub.name}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.expense,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(subscriptionControllerProvider.notifier)
                          .deleteSubscription(sub.id);
                      ref.invalidate(subscriptionsStreamProvider);
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBudgetInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Budget Limit Calculation'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'By default, your Monthly Spending Budget is calculated as:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Card(
                color: Colors.blueAccent,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Center(
                    child: Text(
                      'Monthly Income\n-\nMonthly Savings Goal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text('This keeps your target savings safe from daily expenses.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetProgressAsync = ref.watch(budgetProgressProvider);
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);
    final subsAsync = ref.watch(subscriptionsStreamProvider);
    final currency = ref.watch(preferencesProvider).currency;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Planning')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(budgetProgressProvider);
          ref.invalidate(savingsGoalsStreamProvider);
          ref.invalidate(subscriptionsStreamProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // 1. Budget Card Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Monthly Budget',
                      style: AppTextStyles.title.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showBudgetInfoDialog(context),
                      tooltip: 'About monthly budget limit calculation',
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/budget'),
                  child: const Text('Manage Budgets'),
                ),
              ],
            ),
            VSpace.md,
            budgetProgressAsync.when(
              loading: () => const SkeletonLoader.card(height: 110),
              error: (err, stack) => Text('Error: $err'),
              data: (progress) {
                final pct = progress.progressPercentage;
                final pctText = (pct * 100).toStringAsFixed(0);
                return InkWell(
                  onTap: () => context.push('/budget'),
                  borderRadius: AppRadius.large,
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$currency${progress.totalSpent.toStringAsFixed(0)} / $currency${progress.totalLimit.toStringAsFixed(0)}',
                                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                                ),
                                VSpace.xs,
                                Text('Spent of monthly limit', style: AppTextStyles.caption),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: progress.isExceeded
                                    ? AppColors.expense.withValues(alpha: 0.1)
                                    : AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$pctText%',
                                style: AppTextStyles.caption.copyWith(
                                  color: progress.isExceeded ? AppColors.expense : AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        VSpace.md,
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct > 1.0 ? 1.0 : pct,
                            minHeight: 6,
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress.isExceeded ? AppColors.expense : AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            VSpace.xl,

            // 2. Savings Goals Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Savings Goals',
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/add-savings-goal'),
                  child: const Text('Add Goal'),
                ),
              ],
            ),
            VSpace.sm,
            goalsAsync.when(
              loading: () => const SkeletonLoader.card(height: 120),
              error: (err, stack) => Text('Error: $err'),
              data: (goals) {
                if (goals.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131B2E) : Colors.white,
                      borderRadius: AppRadius.large,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      'No savings goals set yet.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  );
                }
                return Column(
                  children: goals.map((goal) {
                    final pct = goal.targetAmount > 0
                        ? (goal.currentAmount / goal.targetAmount)
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () =>
                            _showGoalDetailsSheet(context, ref, goal, currency),
                        borderRadius: AppRadius.large,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF131B2E)
                                : Colors.white,
                            borderRadius: AppRadius.large,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    goal.name,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${(pct * 100).toStringAsFixed(0)}%',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              VSpace.xs,
                              Text(
                                '$currency${goal.currentAmount.toStringAsFixed(0)} of $currency${goal.targetAmount.toStringAsFixed(0)}',
                                style: AppTextStyles.caption,
                              ),
                              VSpace.md,
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct > 1.0 ? 1.0 : pct,
                                  minHeight: 5,
                                  backgroundColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppColors.accent,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            VSpace.xl,

            // 3. Upcoming Bills (Subscriptions) Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Bills & Subs',
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/add-subscription'),
                  child: const Text('Add Bill'),
                ),
              ],
            ),
            VSpace.sm,
            subsAsync.when(
              loading: () => const SkeletonLoader.listTile(),
              error: (err, stack) => Text('Error: $err'),
              data: (subs) {
                if (subs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131B2E) : Colors.white,
                      borderRadius: AppRadius.large,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      'No recurring bills logged.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131B2E) : Colors.white,
                    borderRadius: AppRadius.large,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: subs.map((sub) {
                      final days = sub.nextBillingDate
                          .difference(DateTime.now())
                          .inDays;
                      final dayText = days == 0
                          ? 'Due Today'
                          : (days == 1 ? 'Due Tomorrow' : 'Due in $days days');

                      return ListTile(
                        onTap: () =>
                            _showBillActionsSheet(context, ref, sub, currency),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withValues(
                            alpha: 0.1,
                          ),
                          child: const Icon(
                            Icons.receipt_rounded,
                            color: Colors.blueAccent,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          sub.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(dayText, style: AppTextStyles.caption),
                        trailing: Text(
                          '$currency${sub.amount.toStringAsFixed(0)}',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
