import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/bouncy_button.dart';
import '../../../../commons/widgets/primary_button.dart';
import '../../../../commons/widgets/animated_linear_progress_bar.dart';
import '../../../../commons/widgets/skeleton_loader.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../savings_goal/domain/entities/savings_goal.dart';
import '../../../savings_goal/presentation/providers/savings_goal_providers.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../auth/presentation/widgets/premium_widgets.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

// Riverpod provider to manage and sync the selected planning sub-tab globally
final planningTabProvider = StateProvider<int>((ref) => 0); // 0 for Budgets, 1 for Goals, 2 for Subs

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {

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
        return const Color(0xFF94A3B8); // Light Slate
    }
  }

  Color _getProgressBarColor(double pct) {
    if (pct >= 0.85) {
      return const Color(0xFFBC5B3E); // Rust Red for close to limit
    } else if (pct >= 0.50) {
      return const Color(0xFFC8A05B); // Gold for warning
    } else {
      return const Color(0xFF7C9473); // Sage Green for safe pacing
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(budgetProgressProvider);
            ref.invalidate(savingsGoalsStreamProvider);
            ref.invalidate(subscriptionsStreamProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              FadeInSlideUp(
                delayMs: 0,
                child: Row(
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
              ),
              const SizedBox(height: 18),

              // Title "Planning" - Delay 80ms
              FadeInSlideUp(
                delayMs: 80,
                child: Text(
                  'Planning',
                  style: GoogleFonts.fraunces(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Horizontal Segmented Switcher Row - Delay 150ms
              FadeInSlideUp(
                delayMs: 150,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildTabButton('Budgets', 0)),
                      Expanded(child: _buildTabButton('Goals', 1)),
                      Expanded(child: _buildTabButton('Subs', 2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Display Dynamic Tab content
              _buildTabContent(currency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final selectedTab = ref.watch(planningTabProvider);
    final isActive = selectedTab == index;
    return GestureDetector(
      onTap: () {
        ref.read(planningTabProvider.notifier).state = index;
      },
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
            color: isActive ? AppColors.background : AppColors.primaryText,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String currency) {
    final selectedTab = ref.watch(planningTabProvider);
    switch (selectedTab) {
      case 0:
        return _buildBudgetsTab(currency);
      case 1:
        return _buildGoalsTab(currency);
      case 2:
        return _buildSubsTab(currency);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- TAB CONTENT 1: BUDGETS ---
  Widget _buildBudgetsTab(String currency) {
    final budgetProgressAsync = ref.watch(budgetProgressProvider);

    return budgetProgressAsync.when(
      loading: () => const Column(
        children: [
          SkeletonLoader.card(height: 90),
          SizedBox(height: 12),
          SkeletonLoader.card(height: 80),
          SizedBox(height: 12),
          SkeletonLoader.card(height: 80),
        ],
      ),
      error: (err, stack) => Center(
        child: Text('Error loading budgets: $err', style: AppTextStyles.body),
      ),
      data: (progress) {
        final totalPct = progress.progressPercentage;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (progress.totalLimit > 0) ...[
              if (progress.isExceeded)
                FadeInSlideUp(
                  delayMs: 200,
                  child: _buildBudgetAlertBanner(
                    context,
                    '🚨 Budget Exceeded!',
                    'You have spent $currency${progress.totalSpent.toStringAsFixed(0)} which exceeds your overall budget limit of $currency${progress.totalLimit.toStringAsFixed(0)} by $currency${(progress.totalSpent - progress.totalLimit).toStringAsFixed(0)}.',
                    const Color(0xFFBC5B3E),
                  ),
                )
              else if (progress.isWarning80)
                FadeInSlideUp(
                  delayMs: 200,
                  child: _buildBudgetAlertBanner(
                    context,
                    '⚠️ Warning: Near Budget Limit',
                    'You have spent ${(progress.progressPercentage * 100).toStringAsFixed(0)}% of your monthly budget limit. Please spend cautiously.',
                    const Color(0xFFC8A05B),
                  ),
                ),
              const SizedBox(height: 12),
            ],
            // MONTHLY LIMIT card
            FadeInSlideUp(
              delayMs: 220,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MONTHLY LIMIT',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.disabledText,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          '$currency${progress.totalSpent.toStringAsFixed(0)} / $currency${progress.totalLimit.toStringAsFixed(0)}',
                          style: AppTextStyles.mono.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AnimatedLinearProgressBar(
                        progress: totalPct,
                        minHeight: 6,
                        backgroundColor: AppColors.border.withOpacity(0.3),
                        valueColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Individual Category Cards
            if (progress.categoryProgresses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('No budgets configured.', style: AppTextStyles.bodySecondary),
                ),
              )
            else
              ...progress.categoryProgresses.asMap().entries.map((entry) {
                final idx = entry.key;
                final catProgress = entry.value;
                final catPct = catProgress.limit > 0 ? (catProgress.spent / catProgress.limit) : 0.0;
                final catName = catProgress.category.name[0].toUpperCase() + catProgress.category.name.substring(1);

                final budgets = ref.read(budgetsStreamProvider).value ?? [];
                final budgetEntity = budgets.cast<Budget?>().firstWhere(
                  (b) => b?.id == catProgress.budgetId,
                  orElse: () => null,
                );

                return FadeInSlideUp(
                  delayMs: 250 + (idx * 50),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: budgetEntity == null
                          ? null
                          : () => context.push('/add-budget', extra: budgetEntity),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(catProgress.category),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      catName,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$currency${catProgress.spent.toStringAsFixed(0)} / $currency${catProgress.limit.toStringAsFixed(0)}',
                                  style: AppTextStyles.monoSecondary.copyWith(
                                    fontSize: 11.5,
                                    color: AppColors.primaryText.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: AnimatedLinearProgressBar(
                                progress: catPct,
                                minHeight: 5,
                                backgroundColor: AppColors.border.withOpacity(0.3),
                                valueColor: _getProgressBarColor(catPct),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 12),
            FadeInSlideUp(
              delayMs: 300 + (progress.categoryProgresses.length * 50),
              child: GestureDetector(
                onTap: () => context.push('/add-budget'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.6), width: 1.0),
                  ),
                  child: Text(
                    'Add Category Budget',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- TAB CONTENT 2: GOALS ---
  Widget _buildGoalsTab(String currency) {
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);

    return goalsAsync.when(
      loading: () => const Column(
        children: [
          SkeletonLoader.card(height: 80),
          SizedBox(height: 12),
          SkeletonLoader.card(height: 80),
        ],
      ),
      error: (err, stack) => Center(
        child: Text('Error loading goals: $err', style: AppTextStyles.body),
      ),
      data: (goals) {
        if (goals.isEmpty) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('No savings goals set yet.', style: AppTextStyles.bodySecondary),
              ),
              FadeInSlideUp(
                delayMs: 200,
                child: _buildAddGoalButton(),
              ),
            ],
          );
        }

        return Column(
          children: [
            ...goals.asMap().entries.map((entry) {
              final idx = entry.key;
              final goal = entry.value;
              final pct = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0.0;

              return FadeInSlideUp(
                delayMs: 200 + (idx * 50),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _showGoalDetailsSheet(context, ref, goal, currency),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    goal.name,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$currency${goal.currentAmount.toStringAsFixed(0)} / $currency${goal.targetAmount.toStringAsFixed(0)}',
                                style: AppTextStyles.monoSecondary.copyWith(
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: AnimatedLinearProgressBar(
                              progress: pct,
                              minHeight: 5,
                              backgroundColor: AppColors.border.withOpacity(0.3),
                              valueColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            FadeInSlideUp(
              delayMs: 250 + (goals.length * 50),
              child: _buildAddGoalButton(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddGoalButton() {
    return GestureDetector(
      onTap: () => context.push('/add-savings-goal'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.6), width: 1.0),
        ),
        child: Text(
          'Add Savings Goal',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- TAB CONTENT 3: SUBS ---
  Widget _buildSubsTab(String currency) {
    final subsAsync = ref.watch(subscriptionsStreamProvider);

    return subsAsync.when(
      loading: () => const Column(
        children: [
          SkeletonLoader.card(height: 80),
          SizedBox(height: 12),
          SkeletonLoader.card(height: 80),
        ],
      ),
      error: (err, stack) => Center(
        child: Text('Error loading subscriptions: $err', style: AppTextStyles.body),
      ),
      data: (subs) {
        if (subs.isEmpty) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('No recurring bills logged yet.', style: AppTextStyles.bodySecondary),
              ),
              FadeInSlideUp(
                delayMs: 200,
                child: _buildAddSubButton(),
              ),
            ],
          );
        }

        return Column(
          children: [
            ...subs.asMap().entries.map((entry) {
              final idx = entry.key;
              final sub = entry.value;
              final days = sub.nextBillingDate.difference(DateTime.now()).inDays;
              final String dueLabel;
              if (days == 0) {
                dueLabel = 'Due today';
              } else if (days < 0) {
                dueLabel = 'Overdue by ${days.abs()} days';
              } else {
                dueLabel = 'Due in $days days';
              }

              return FadeInSlideUp(
                delayMs: 200 + (idx * 50),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _showBillActionsSheet(context, ref, sub, currency),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5E7A8A), // Blue steel
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    sub.name,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$currency${sub.amount.toStringAsFixed(0)} / ${sub.billingCycle.name.toLowerCase()}',
                                style: AppTextStyles.monoSecondary.copyWith(
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            dueLabel,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: days <= 2 ? const Color(0xFFBC5B3E) : AppColors.disabledText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            FadeInSlideUp(
              delayMs: 250 + (subs.length * 50),
              child: _buildAddSubButton(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddSubButton() {
    return GestureDetector(
      onTap: () => context.push('/add-subscription'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.6), width: 1.0),
        ),
        child: Text(
          'Add Subscription / Bill',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- ACTIONS & DIALOGS FROM ORIGINAL IMPLEMENTATION ---
  void _showGoalDetailsSheet(BuildContext context, WidgetRef ref, SavingsGoal goal, String currency) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0.0;
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(0.0, double.infinity);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
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
                        color: AppColors.border,
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
                          style: GoogleFonts.fraunces(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFBC5B3E),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              title: const Text('Delete Goal?', style: TextStyle(color: Colors.white)),
                              content: Text('Are you sure you want to delete "${goal.name}"?', style: const TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFBC5B3E)),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref.read(savingsGoalControllerProvider.notifier).deleteGoal(goal.id);
                            ref.invalidate(savingsGoalsStreamProvider);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Target Date: ${DateFormat('dd MMMM yyyy').format(goal.targetDate)}',
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved: $currency${goal.currentAmount.toStringAsFixed(0)} / $currency${goal.targetAmount.toStringAsFixed(0)}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedLinearProgressBar(
                      progress: pct,
                      minHeight: 6,
                      backgroundColor: AppColors.border.withOpacity(0.3),
                      valueColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (remaining > 0)
                    Text(
                      'Needs $currency${remaining.toStringAsFixed(0)} more to reach target.',
                      style: AppTextStyles.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.disabledText,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddMoneyDialog(context, ref, goal, false),
                          icon: const Icon(Icons.remove),
                          label: const Text('Withdraw'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFBC5B3E),
                            side: const BorderSide(color: Color(0xFFBC5B3E)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddMoneyDialog(context, ref, goal, true),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Cash'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showAddMoneyDialog(BuildContext context, WidgetRef ref, SavingsGoal goal, bool isAdding) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            isAdding ? 'Add money to "${goal.name}"' : 'Withdraw from "${goal.name}"',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppColors.primary),
                helperText: !isAdding ? 'Available: ${goal.currentAmount.toStringAsFixed(0)}' : null,
                helperStyle: const TextStyle(color: Colors.white60),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter an amount';
                final amount = double.tryParse(val);
                if (amount == null || amount <= 0) return 'Please enter a valid positive amount';
                if (!isAdding && amount > goal.currentAmount) return 'Insufficient goal funds';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
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
                  currentAmount: (goal.currentAmount + change).clamp(0, double.infinity),
                  targetDate: goal.targetDate,
                  createdAt: goal.createdAt,
                );

                await ref.read(savingsGoalControllerProvider.notifier).saveGoal(updated);
                ref.invalidate(savingsGoalsStreamProvider);

                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close bottom sheet
              },
              child: Text('Confirm', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  void _showBillActionsSheet(BuildContext context, WidgetRef ref, Subscription sub, String currency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  sub.name,
                  style: GoogleFonts.fraunces(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Amount: $currency${sub.amount.toStringAsFixed(0)} • Billing: ${sub.billingCycle.name.toUpperCase()}',
                  style: AppTextStyles.bodySecondary,
                ),
                Text(
                  'Next Due Date: ${DateFormat('dd MMMM yyyy').format(sub.nextBillingDate)}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.disabledText),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Icon(Icons.edit_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Edit Bill Details', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/add-subscription', extra: sub);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFBC5B3E),
                    child: Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  title: const Text('Delete Bill / Sub', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Delete Bill?', style: TextStyle(color: Colors.white)),
                        content: Text('Are you sure you want to stop tracking "${sub.name}"?', style: const TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFBC5B3E)),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(subscriptionControllerProvider.notifier).deleteSubscription(sub.id);
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

  Widget _buildBudgetAlertBanner(BuildContext context, String title, String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            color == const Color(0xFFBC5B3E) ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
