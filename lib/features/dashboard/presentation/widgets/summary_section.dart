import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import 'summary_card.dart';

class SummarySection extends ConsumerWidget {
  final double income;
  final double expense;
  final double totalSaved;

  const SummarySection({
    super.key,
    required this.income,
    required this.expense,
    required this.totalSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(preferencesProvider).currency;

    return Row(
      children: [
        SummaryCard(
          title: 'Income',
          value: '$currency${income.toStringAsFixed(0)}',
          icon: Icons.arrow_downward_rounded,
          color: AppColors.income,
        ),

        HSpace.md,

        SummaryCard(
          title: 'Expense',
          value: '$currency${expense.toStringAsFixed(0)}',
          icon: Icons.arrow_upward_rounded,
          color: AppColors.expense,
        ),

        HSpace.md,

        SummaryCard(
          title: 'Total Saved',
          value: '$currency${totalSaved.toStringAsFixed(0)}',
          icon: Icons.savings_outlined,
          color: AppColors.accent,
        ),
      ],
    );
  }
}