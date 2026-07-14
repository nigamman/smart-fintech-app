import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../commons/widgets/loading_indicator.dart';
import '../../../../commons/widgets/primary_button.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quick_action_section.dart';
import '../widgets/recent_transaction.dart';
import '../widgets/savings_goals_dashboard_widget.dart';
import '../widgets/summary_section.dart';
import '../../../savings_goal/presentation/providers/savings_goal_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Widget _buildBudgetAlertBanner(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(budgetProgressProvider);
    return progressAsync.maybeWhen(
      data: (progress) {
        if (progress.totalLimit == 0) return const SizedBox.shrink();

        final pctText = (progress.progressPercentage * 100).toStringAsFixed(0);
        Widget? alertWidget;

        if (progress.isExceeded) {
          alertWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget Exceeded',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You have spent ₹${progress.totalSpent.toStringAsFixed(0)} of your ₹${progress.totalLimit.toStringAsFixed(0)} limit.',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else if (progress.isWarning80) {
          alertWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget Warning ($pctText%)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You have spent ₹${progress.totalSpent.toStringAsFixed(0)} of your ₹${progress.totalLimit.toStringAsFixed(0)} limit.',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (alertWidget != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              alertWidget,
              VSpace.xl,
            ],
          );
        }
        return const SizedBox.shrink();
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const LoadingIndicator(),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 64,
                ),
                VSpace.lg,
                Text(
                  'Failed to load dashboard data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                VSpace.sm,
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                VSpace.xl,
                PrimaryButton(
                  text: 'Retry',
                  onPressed: () => ref.refresh(dashboardDataProvider),
                ),
              ],
            ),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () => ref.refresh(dashboardDataProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GreetingHeader(
                    userName: data.userName,
                  ),

                  VSpace.xl,

                  _buildBudgetAlertBanner(context, ref),

                  BalanceCard(
                    safeToSpend: data.safeToSpend,
                    totalBalance: data.totalBalance,
                  ),

                  VSpace.xl,

                  SummarySection(
                    income: data.totalIncome,
                    expense: data.totalExpense,
                    totalSaved: goalsAsync.maybeWhen(
                      data: (goals) => goals.fold<double>(0.0, (sum, item) => sum + item.currentAmount),
                      orElse: () => 0.0,
                    ),
                  ),

                  VSpace.xl,

                  const QuickActionsSection(),

                  VSpace.xl,

                  const SavingsGoalsDashboardWidget(),

                  VSpace.xl,

                  RecentTransactions(
                    transactions: data.recentTransactions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}