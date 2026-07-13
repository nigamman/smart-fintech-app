import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.title,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}