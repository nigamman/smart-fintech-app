import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/enums/transaction_type.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class TransactionTile extends StatelessWidget {
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = type == TransactionType.income;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,

      leading: CircleAvatar(
        backgroundColor: isIncome
            ? AppColors.income.withValues(alpha: 0.12)
            : AppColors.expense.withValues(alpha: 0.12),

        child: Icon(
          isIncome
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          color: isIncome
              ? AppColors.income
              : AppColors.expense,
        ),
      ),

      title: Text(
        title,
        style: AppTextStyles.body,
      ),

      subtitle: Text(
        '$category • ${DateFormat('dd MMM').format(date)}',
        style: AppTextStyles.caption,
      ),

      trailing: Text(
        '${isIncome ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
        style: AppTextStyles.body.copyWith(
          color: isIncome
              ? AppColors.income
              : AppColors.expense,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}