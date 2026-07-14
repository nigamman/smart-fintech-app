import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'summary_card.dart';

class SummarySection extends StatelessWidget {
  final double income;
  final double expense;
  final double savingsGoal;

  const SummarySection({
    super.key,
    required this.income,
    required this.expense,
    required this.savingsGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SummaryCard(
          title: 'Income',
          value: '₹${income.toStringAsFixed(0)}',
          icon: Icons.arrow_downward_rounded,
          color: AppColors.income,
        ),

        HSpace.md,

        SummaryCard(
          title: 'Expense',
          value: '₹${expense.toStringAsFixed(0)}',
          icon: Icons.arrow_upward_rounded,
          color: AppColors.expense,
        ),

        HSpace.md,

        SummaryCard(
          title: 'Savings',
          value: '₹${savingsGoal.toStringAsFixed(0)}',
          icon: Icons.savings_outlined,
          color: AppColors.accent,
        ),
      ],
    );
  }
}