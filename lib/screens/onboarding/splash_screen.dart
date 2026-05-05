import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.dustyRose.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                size: 40,
                color: AppColors.dustyRose,
              ),
            ),
            const SizedBox(height: 20),
            Text('Wedding Planner', style: AppTextStyles.displaySmall),
            const SizedBox(height: 8),
            Text('Loading...', style: AppTextStyles.cardSubtitle),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.dustyRose),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
