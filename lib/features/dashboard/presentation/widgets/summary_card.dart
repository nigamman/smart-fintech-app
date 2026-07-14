import 'package:flutter/material.dart';

import '../../../../commons/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
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
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: color,
              ),
            ),

            VSpace.lg,

            Text(
              title.toUpperCase(),
              style: AppTextStyles.label.copyWith(
                letterSpacing: 1.2,
              ),
            ),

            VSpace.xs,

            Text(
              value,
              style: AppTextStyles.h3,
            ),
          ],
        ),
      ),
    );
  }
}