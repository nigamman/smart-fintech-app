import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../commons/widgets/loading_indicator.dart';
import '../../../../commons/widgets/primary_button.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quick_action_section.dart';
import '../widgets/recent_transaction.dart';
import '../widgets/summary_section.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

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

                  BalanceCard(
                    safeToSpend: data.safeToSpend,
                    totalBalance: data.totalBalance,
                  ),

                  VSpace.xl,

                  SummarySection(
                    income: data.totalIncome,
                    expense: data.totalExpense,
                    savingsGoal: data.monthlySavingsGoal,
                  ),

                  VSpace.xl,

                  const QuickActionsSection(),

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