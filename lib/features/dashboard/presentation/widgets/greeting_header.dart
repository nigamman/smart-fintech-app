import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../commons/widgets/bouncy_button.dart';

class GreetingHeader extends StatelessWidget {
  final String userName;

  const GreetingHeader({
    super.key,
    required this.userName,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // FT square badge
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            'FT',
            style: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Center Greeting text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getGreeting(),
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName.toUpperCase(),
                style: AppTextStyles.label.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),

        // Profile letter avatar circle
        BouncyButton(
          onTap: () => context.push('/settings'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondaryText.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}