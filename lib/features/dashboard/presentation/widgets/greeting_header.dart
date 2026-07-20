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
    final initials = userName.trim().isNotEmpty
        ? (userName.trim().split(' ').length >= 2
            ? '${userName.trim().split(' ')[0][0]}${userName.trim().split(' ')[1][0]}'
            : userName.trim().split(' ')[0][0])
        : 'U';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Gold App logo badge
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.primary,
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.asset(
              'assets/icons/icon-master-1024.png',
              fit: BoxFit.cover,
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials.toUpperCase(),
              style: AppTextStyles.label.copyWith(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}