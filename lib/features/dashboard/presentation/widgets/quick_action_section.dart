import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import 'quick_action_button.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          QuickActionButton(
            icon: Icons.remove_circle_outline,
            title: 'Expense',
            onTap: () => context.push('/add-transaction?type=expense'),
          ),

          const SizedBox(width: 10),

          QuickActionButton(
            icon: Icons.add_circle_outline,
            title: 'Income',
            onTap: () => context.push('/add-transaction?type=income'),
          ),

          const SizedBox(width: 10),

          QuickActionButton(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Budget',
            onTap: () => context.push('/budget'),
          ),

          const SizedBox(width: 10),

          QuickActionButton(
            icon: Icons.analytics_outlined,
            title: 'Analytics',
            onTap: () => context.push('/analytics'),
          ),

          const SizedBox(width: 10),

          QuickActionButton(
            icon: Icons.calendar_month_outlined,
            title: 'Calendar',
            onTap: () => context.push('/calendar'),
          ),

          const SizedBox(width: 10),

          QuickActionButton(
            icon: Icons.card_membership_outlined,
            title: 'Subs',
            onTap: () => context.push('/subscriptions'),
          ),
        ],
      ),
    );
  }
}