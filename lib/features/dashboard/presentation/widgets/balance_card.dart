import 'package:flutter/material.dart';
import '../../../../commons/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class BalanceCard extends StatelessWidget {
  final double safeToSpend;
  final double totalBalance;

  const BalanceCard({
    super.key,
    required this.safeToSpend,
    required this.totalBalance,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safe to Spend Today',
            style: AppTextStyles.caption,
          ),

          VSpace.sm,

          Text(
            '₹${safeToSpend.toStringAsFixed(0)}',
            style: AppTextStyles.display,
          ),

          VSpace.xs,

          Text(
            'Based on your budget and spending pattern.',
            style: AppTextStyles.caption,
          ),

          VSpace.lg,

          const Divider(),

          VSpace.md,

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: AppTextStyles.bodySecondary,
              ),

              Text(
                '₹${totalBalance.toStringAsFixed(0)}',
                style: AppTextStyles.title.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}