import 'package:flutter/material.dart';
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
          onTap: () {},
        ),

        HSpace.md,

        QuickActionButton(
          icon: Icons.add_circle_outline,
          title: 'Income',
          onTap: () {},
        ),

        HSpace.md,

        QuickActionButton(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Budget',
          onTap: () {},
        ),
      ],
    );
  }
}