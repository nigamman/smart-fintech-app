import 'package:flutter/material.dart';
import '../../../../commons/widgets/app_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                icon,
                size: 18,
                color: color,
              ),
            ),

            VSpace.md,

            Text(
              title,
              style: AppTextStyles.caption,
            ),

            VSpace.xs,

            Text(
              value,
              style: AppTextStyles.title,
            ),
          ],
        ),
      ),
    );
  }
}