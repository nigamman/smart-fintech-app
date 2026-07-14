import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../commons/widgets/section_header.dart';
import '../../../../commons/widgets/transaction_title.dart';
import '../../../../core/enums/transaction_category.dart';
import '../../../../core/enums/transaction_type.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../transaction/data/models/transaction_model.dart';

class RecentTransactions extends StatelessWidget {
  final List<TransactionModel> transactions;

  const RecentTransactions({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Transactions',
          actionText: 'See All',
          onActionTap: () => context.push('/transactions'),
        ),

        VSpace.md,

        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: Text(
                'No recent transactions yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...transactions.map(
            (tx) => TransactionTile(
              title: tx.note != null && tx.note!.isNotEmpty ? tx.note! : _getCategoryName(tx.category),
              category: _getCategoryName(tx.category),
              amount: tx.amount,
              date: tx.transactionDate,
              type: tx.type,
            ),
          ),
      ],
    );
  }

  String _getCategoryName(TransactionCategory category) {
    final name = category.name;
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }
}