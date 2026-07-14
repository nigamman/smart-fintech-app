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
import '../../domain/enums/billing_cycle.dart';
import '../providers/subscription_providers.dart';
import '../../../../commons/widgets/skeleton_loader.dart';

class SubscriptionListScreen extends ConsumerWidget {
  const SubscriptionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsStreamProvider);
    final monthlyTotal = ref.watch(subscriptionMonthlyCostProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
      ),
      body: subscriptionsAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SkeletonLoader.card(height: 110),
            VSpace.xl,
            const SkeletonLoader(width: 140, height: 20),
            VSpace.md,
            const SkeletonLoader.listTile(),
            VSpace.md,
            const SkeletonLoader.listTile(),
            VSpace.md,
            const SkeletonLoader.listTile(),
          ],
        ),
        error: (err, stack) => Center(
          child: Text('Error loading subscriptions: $err'),
        ),
        data: (subs) {
          if (subs.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(subscriptionsStreamProvider);
              },
              child: Stack(
                children: [
                  ListView(), // Scrollable background to trigger pull-to-refresh
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_membership_outlined,
                            size: 64,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                          VSpace.lg,
                          Text(
                            'No subscriptions tracked yet',
                            style: AppTextStyles.h3,
                          ),
                          VSpace.sm,
                          Text(
                            'Track monthly or annual recurring payments like Netflix, Spotify, or Rent.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
                          ),
                          VSpace.xl,
                          PrimaryButton(
                            text: 'Add subscription',
                            onPressed: () => context.push('/add-subscription'),
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
              ref.invalidate(subscriptionsStreamProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Monthly Commitment Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF673AB7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppRadius.large,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Commitment',
                        style: AppTextStyles.caption.copyWith(color: AppColors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${monthlyTotal.toStringAsFixed(0)} / month',
                        style: AppTextStyles.h1.copyWith(color: AppColors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Across ${subs.length} active subscriptions',
                        style: AppTextStyles.caption.copyWith(color: AppColors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                VSpace.xl,

                Text(
                  'Upcoming Renewals',
                  style: AppTextStyles.h3,
                ),
                VSpace.sm,

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subs.length,
                  separatorBuilder: (context, index) => VSpace.md,
                  itemBuilder: (context, index) {
                    final sub = subs[index];
                    final dateStr = DateFormat('dd MMM yyyy').format(sub.nextBillingDate);
                    final cycleText = sub.billingCycle == BillingCycle.weekly
                        ? 'week'
                        : (sub.billingCycle == BillingCycle.monthly ? 'month' : 'year');

                    // Calculate days remaining
                    final daysRemaining = sub.nextBillingDate.difference(DateTime.now()).inDays;
                    String daysText = '';
                    Color badgeColor = AppColors.secondaryText.withValues(alpha: 0.1);
                    Color textColor = AppColors.secondaryText;

                    if (daysRemaining == 0) {
                      daysText = 'Today';
                      badgeColor = AppColors.income.withValues(alpha: 0.12);
                      textColor = AppColors.income;
                    } else if (daysRemaining == 1) {
                      daysText = 'Tomorrow';
                      badgeColor = Colors.orange.withValues(alpha: 0.12);
                      textColor = Colors.orange.shade800;
                    } else if (daysRemaining > 1) {
                      daysText = '$daysRemaining days';
                      if (daysRemaining <= 3) {
                        badgeColor = Colors.orange.withValues(alpha: 0.12);
                        textColor = Colors.orange.shade800;
                      } else {
                        badgeColor = AppColors.border;
                        textColor = AppColors.primaryText;
                      }
                    } else {
                      daysText = 'Overdue';
                      badgeColor = AppColors.expense.withValues(alpha: 0.12);
                      textColor = AppColors.expense;
                    }

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.large,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      color: AppColors.surface,
                      child: InkWell(
                        onTap: () => context.push('/add-subscription', extra: sub),
                        borderRadius: AppRadius.large,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: const Icon(Icons.card_membership_outlined, color: AppColors.primary),
                              ),
                              HSpace.md,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sub.name,
                                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${sub.amount.toStringAsFixed(0)} / $cycleText • Next: $dateStr',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: AppRadius.medium,
                                ),
                                child: Text(
                                  daysText,
                                  style: AppTextStyles.caption.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-subscription'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
