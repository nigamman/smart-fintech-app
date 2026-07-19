import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/enums/transaction_type.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';

class TransactionTile extends ConsumerWidget {
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final VoidCallback? onTap;
  final bool isEncrypted;

  const TransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.onTap,
    this.isEncrypted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = type == TransactionType.income;
    final currency = ref.watch(preferencesProvider).currency;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,

      leading: CircleAvatar(
        backgroundColor: isEncrypted
            ? Colors.grey.withOpacity(0.12)
            : (isIncome
                ? AppColors.income.withValues(alpha: 0.12)
                : AppColors.expense.withValues(alpha: 0.12)),

        child: Icon(
          isEncrypted
              ? Icons.lock_outline_rounded
              : (isIncome
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded),
          color: isEncrypted
              ? Colors.grey
              : (isIncome
                  ? AppColors.income
                  : AppColors.expense),
          size: 18,
        ),
      ),

      title: Text(
        isEncrypted ? 'Encrypted Sync Backup' : title,
        style: AppTextStyles.body.copyWith(
          color: isEncrypted ? Colors.grey : null,
          fontStyle: isEncrypted ? FontStyle.italic : null,
        ),
      ),

      subtitle: Text(
        isEncrypted
            ? 'Zero-Knowledge Protected • ${DateFormat('dd MMM').format(date)}'
            : '$category • ${DateFormat('dd MMM').format(date)}',
        style: AppTextStyles.caption,
      ),

      trailing: Text(
        isEncrypted ? '••••' : '${isIncome ? '+' : '-'}$currency${amount.toStringAsFixed(0)}',
        style: AppTextStyles.body.copyWith(
          color: isEncrypted
              ? Colors.grey
              : (isIncome
                  ? AppColors.income
                  : AppColors.expense),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}