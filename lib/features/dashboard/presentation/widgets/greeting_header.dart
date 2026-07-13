import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class GreetingHeader extends StatelessWidget {
  final String userName;

  const GreetingHeader({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning 👋',
                style: AppTextStyles.caption,
              ),
              Text(
                userName,
                style: AppTextStyles.h2,
              ),
            ],
          ),
        ),
        const CircleAvatar(
          radius: 22,
          child: Icon(Icons.person_outline),
        ),
      ],
    );
  }
}