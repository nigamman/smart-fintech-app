import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class DashboardAppBar extends StatelessWidget {
  final String userName;

  const DashboardAppBar({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
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
        const CircleAvatar(
          radius: 22,
          child: Icon(Icons.person),
        ),
      ],
    );
  }
}