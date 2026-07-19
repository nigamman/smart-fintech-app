import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/skeleton_loader.dart';
import '../../../../commons/widgets/transaction_title.dart';
import '../../../../commons/widgets/bouncy_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../savings_goal/presentation/providers/savings_goal_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../presentation/providers/dashboard_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/greeting_header.dart';
import 'main_navigation_screen.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);
    final subsAsync = ref.watch(subscriptionsStreamProvider);
    final budgetProgressAsync = ref.watch(budgetProgressProvider);
    final currency = ref.watch(preferencesProvider).currency;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 140, height: 24),
                VSpace.lg,
                const SkeletonLoader.card(height: 220),
                VSpace.lg,
                const SkeletonLoader.card(height: 120),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error loading dashboard: $error',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
          data: (dashboardData) {
            final List<Map<String, dynamic>> attentionAlerts = [];

            // Budget Alerts (Overall + Category Specific)
            budgetProgressAsync.whenData((progress) {
              // 1. Overall monthly budget alerts
              if (progress.totalLimit > 0) {
                if (progress.isExceeded) {
                  attentionAlerts.add({
                    'text': 'Monthly budget exceeded',
                    'subtitle': 'Limit $currency${progress.totalLimit.toStringAsFixed(0)} • Spent $currency${progress.totalSpent.toStringAsFixed(0)}',
                    'color': AppColors.expense,
                    'icon': Icons.warning_amber_rounded,
                    'tag': 'Limit',
                  });
                } else if (progress.isWarning80) {
                  final remaining = progress.totalLimit - progress.totalSpent;
                  final pct = (progress.progressPercentage * 100).toStringAsFixed(0);
                  attentionAlerts.add({
                    'text': 'Monthly budget at $pct%',
                    'subtitle': '$currency${remaining.toStringAsFixed(0)} remaining for the month',
                    'color': const Color(0xFFC8A05B),
                    'icon': Icons.warning_amber_rounded,
                    'tag': 'Limit',
                  });
                }
              }

              // 2. Individual category budget alerts
              for (final catProgress in progress.categoryProgresses) {
                final catName = catProgress.category.name[0].toUpperCase() + catProgress.category.name.substring(1);
                if (catProgress.isExceeded) {
                  attentionAlerts.add({
                    'text': '$catName budget exceeded',
                    'subtitle': 'Spent limit completely consumed.',
                    'color': AppColors.expense,
                    'icon': Icons.warning_amber_rounded,
                    'tag': 'Budget',
                  });
                } else if (catProgress.isWarning80) {
                  final remaining = catProgress.limit - catProgress.spent;
                  final pct = (catProgress.progressPercentage * 100).toStringAsFixed(0);
                  attentionAlerts.add({
                    'text': '$catName budget at $pct%',
                    'subtitle': '$currency${remaining.toStringAsFixed(0)} left for this category',
                    'color': const Color(0xFFC8A05B),
                    'icon': Icons.warning_amber_rounded,
                    'tag': 'Budget',
                  });
                }
              }
            });

            // Subscription Renewal Alert
            subsAsync.whenData((subs) {
              final closeRenewals = subs.where((sub) {
                final days = sub.nextBillingDate.difference(DateTime.now()).inDays;
                return days >= 0 && days <= 2;
              });
              for (final sub in closeRenewals) {
                final days = sub.nextBillingDate.difference(DateTime.now()).inDays;
                final dayStr = days == 0 ? 'today' : (days == 1 ? 'tomorrow' : 'in $days days');
                attentionAlerts.add({
                  'text': '${sub.name} renews $dayStr',
                  'subtitle': '$currency${sub.amount.toStringAsFixed(0)} will be charged on the ${sub.nextBillingDate.day}st',
                  'color': AppColors.primary,
                  'icon': Icons.repeat_rounded,
                  'tag': 'Sub',
                });
              }
            });

            // Goals Alert
            goalsAsync.whenData((goals) {
              for (final goal in goals) {
                if (goal.currentAmount < goal.targetAmount && goal.currentAmount / goal.targetAmount < 0.8) {
                  final remaining = goal.targetAmount - goal.currentAmount;
                  final pct = (goal.currentAmount / goal.targetAmount * 100).toStringAsFixed(0);
                  attentionAlerts.add({
                    'text': '${goal.name} goal • $pct% funded',
                    'subtitle': '$currency${remaining.toStringAsFixed(0)} more to hit target',
                    'color': AppColors.primary,
                    'icon': Icons.flag_outlined,
                    'tag': 'Goal',
                  });
                }
              }
            });

            // Calculate Health Score
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
              alertRenewals: attentionAlerts.where((a) => a['tag'] == 'Sub').length,
            );

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                ref.invalidate(dashboardDataProvider);
                ref.invalidate(savingsGoalsStreamProvider);
                ref.invalidate(subscriptionsStreamProvider);
                ref.invalidate(budgetProgressProvider);
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stagger 1: Greeting Header
                    FadeInWidget(
                      delay: Duration.zero,
                      child: GreetingHeader(userName: dashboardData.userName),
                    ),
                    VSpace.xl,

                    // Stagger 2: Unified Hero Balance Card
                    FadeInWidget(
                      delay: const Duration(milliseconds: 100),
                      child: BalanceCard(
                        safeToSpend: dashboardData.safeToSpend,
                        totalBalance: dashboardData.totalBalance,
                        monthlyIncome: dashboardData.monthlyIncome,
                        totalExpense: dashboardData.totalExpense,
                        healthScore: score,
                      ),
                    ),
                    VSpace.xl,

                    // Stagger 3: Smart Action Inbox
                    if (attentionAlerts.isNotEmpty) ...[
                      FadeInWidget(
                        delay: const Duration(milliseconds: 200),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 1.0),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'SMART ACTION INBOX',
                                    style: AppTextStyles.label.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.border, width: 1.0),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      attentionAlerts.length.toString(),
                                      style: AppTextStyles.label.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: attentionAlerts.length,
                                separatorBuilder: (context, index) => const Divider(
                                  height: 16,
                                  color: AppColors.border,
                                  thickness: 0.5,
                                ),
                                itemBuilder: (context, index) {
                                  final alert = attentionAlerts[index];
                                  return Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: (alert['color'] as Color).withOpacity(0.3),
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Icon(
                                          alert['icon'] as IconData,
                                          color: alert['color'] as Color,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              alert['text']?.toString() ?? '',
                                              style: AppTextStyles.body.copyWith(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              alert['subtitle']?.toString() ?? '',
                                              style: AppTextStyles.caption.copyWith(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        alert['tag']?.toString() ?? '',
                                        style: AppTextStyles.label.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.disabledText,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      VSpace.xl,
                    ],

                    // Stagger 4: Quick Actions circular row
                    FadeInWidget(
                      delay: const Duration(milliseconds: 300),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickActionButton(
                            icon: Icons.remove,
                            label: 'Expense',
                            onTap: () => context.push('/add-transaction?type=expense'),
                          ),
                          _buildQuickActionButton(
                            icon: Icons.add,
                            label: 'Income',
                            onTap: () => context.push('/add-transaction?type=income'),
                          ),
                          _buildQuickActionButton(
                            icon: Icons.swap_horiz_rounded,
                            label: 'Split',
                            onTap: () => context.push('/split-ledger'),
                          ),
                          _buildQuickActionButton(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Ask AI',
                            onTap: () => context.push('/insights'),
                          ),
                        ],
                      ),
                    ),
                    VSpace.xl,

                    // Stagger 5: Today's Ledger Section
                    FadeInWidget(
                      delay: const Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Today's ledger",
                                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                              ),
                              BouncyButton(
                                onTap: () => context.push('/transactions'),
                                child: Text(
                                  'View all',
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border, width: 1.0),
                              ),
                              child: Text(
                                'No transactions recorded today.',
                                style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border, width: 1.0),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                children: dashboardData.recentTransactions.take(3).map((tx) {
                                  final isExpense = tx.type == TransactionType.expense;
                                  final prefix = isExpense ? '-' : '+';
                                  final amountText = '$prefix$currency${tx.amount.toStringAsFixed(0)}';
                                  final formatTime = DateFormat('h:mm a').format(tx.transactionDate);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      children: [
                                        // Category mini color block
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: isExpense ? AppColors.expense : AppColors.income,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    tx.note ?? tx.category.name,
                                                    style: AppTextStyles.body.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  if (tx.isEncrypted) ...[
                                                    const SizedBox(width: 6),
                                                    const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.disabledText),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${tx.category.name}  •  $formatTime',
                                                style: AppTextStyles.caption.copyWith(fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Monospace ledger format amount
                                        Text(
                                          amountText,
                                          style: AppTextStyles.mono.copyWith(
                                            fontSize: 14,
                                            color: isExpense ? AppColors.expense : AppColors.income,
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
                    ),
                    VSpace.xl,

                    // Stagger 6: Savings Vaults horizontal sliders
                    goalsAsync.maybeWhen(
                      data: (goals) {
                        if (goals.isEmpty) return const SizedBox.shrink();
                        return FadeInWidget(
                          delay: const Duration(milliseconds: 500),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Savings vaults',
                                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  BouncyButton(
                                    onTap: () => context.push('/savings-goals'),
                                    child: Text(
                                      'Manage',
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              VSpace.md,
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: goals.map((goal) {
                                    final pct = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) : 0.0;
                                    return BouncyButton(
                                      onTap: () => context.push('/savings-goals'),
                                      child: Container(
                                        width: 150,
                                        margin: const EdgeInsets.only(right: 14, bottom: 4),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: AppColors.border, width: 1.0),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            AnimatedProgressRing(
                                              progress: pct,
                                              scrollController: _scrollController,
                                            ),
                                            VSpace.md,
                                            Text(
                                              goal.name,
                                              style: AppTextStyles.body.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            // Monospace targets
                                            Text(
                                              '$currency${goal.currentAmount.toStringAsFixed(0)} / $currency${goal.targetAmount.toStringAsFixed(0)}',
                                              style: AppTextStyles.monoSecondary.copyWith(
                                                fontSize: 10.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetAlertBanner(BuildContext context, String title, String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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

// Reusable micro-interaction fade in slide animation wrapper
// Reusable micro-interaction fade in slide animation wrapper
class FadeInWidget extends ConsumerStatefulWidget {
  final Widget child;
  final Duration delay;

  const FadeInWidget({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  ConsumerState<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends ConsumerState<FadeInWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainNavigationIndexProvider, (previous, next) {
      if (next == 0) {
        Future.delayed(widget.delay, () {
          if (mounted) {
            _controller.forward(from: 0.0);
          }
        });
      } else {
        _controller.reset();
      }
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class AnimatedProgressRing extends ConsumerStatefulWidget {
  final double progress;
  final double size;
  final ScrollController scrollController;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    required this.scrollController,
    this.size = 50.0,
  });

  @override
  ConsumerState<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends ConsumerState<AnimatedProgressRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    
    // Tween sequence going from 0.0 -> 1.0 (Full) -> target progress
    _animation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: widget.progress).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
    ]).animate(_controller);

    widget.scrollController.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (_hasTriggered || !mounted) return;
    if (!widget.scrollController.hasClients) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.attached) {
      final position = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;

      // Trigger animation if the top of the ring is anywhere within or above the screen viewport
      if (position.dy < screenHeight - 20) {
        _hasTriggered = true;
        widget.scrollController.removeListener(_checkVisibility);
        _controller.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(mainNavigationIndexProvider, (previous, next) {
      if (next == 0) {
        if (!_hasTriggered) {
          widget.scrollController.removeListener(_checkVisibility);
          widget.scrollController.addListener(_checkVisibility);
        }
        _checkVisibility();
      } else {
        _hasTriggered = false;
        _controller.reset();
        widget.scrollController.removeListener(_checkVisibility);
      }
    });

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            value: _animation.value.clamp(0.0, 1.0),
            strokeWidth: 3.5,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      },
    );
  }
}
