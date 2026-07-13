import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'summary_card.dart';

class SummarySection extends StatelessWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SummaryCard(
          title: 'Income',
          value: '₹50K',
          icon: Icons.arrow_downward_rounded,
          color: AppColors.income,
        ),

        HSpace.md,

        SummaryCard(
          title: 'Expense',
          value: '₹25K',
          icon: Icons.arrow_upward_rounded,
          color: AppColors.expense,
        ),

        HSpace.md,

        SummaryCard(
          title: 'Savings',
          value: '₹25K',
          icon: Icons.savings_outlined,
          color: AppColors.accent,
        ),
      ],
    );
  }
}