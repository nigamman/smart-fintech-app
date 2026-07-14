import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import 'quick_action_button.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        QuickActionButton(
          icon: Icons.remove_circle_outline,
          title: 'Expense',
          onTap: () => context.push('/add-transaction?type=expense'),
        ),

        HSpace.md,

        QuickActionButton(
          icon: Icons.add_circle_outline,
          title: 'Income',
          onTap: () => context.push('/add-transaction?type=income'),
        ),

        HSpace.md,

        QuickActionButton(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Budget',
          onTap: () => context.push('/budget'),
        ),
      ],
    );
  }
}