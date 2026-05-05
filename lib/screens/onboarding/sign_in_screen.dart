import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.dustyRose.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 50,
                  color: AppColors.dustyRose,
                ),
              ),
              const SizedBox(height: 28),
              Text('Wedding Planner', style: AppTextStyles.displayMedium),
              const SizedBox(height: 12),
              Text(
                'Plan your perfect day, beautifully organised.',
                style: AppTextStyles.cardSubtitle,
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              // Features list
              _FeatureRow(
                icon: Icons.table_chart_outlined,
                text: 'All data saved to your own Google Sheet',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.lock_outline,
                text: 'Your data stays in your Google Drive',
              ),
              const SizedBox(height: 12),
              _FeatureRow(
                icon: Icons.devices,
                text: 'Access from any device',
              ),
              const Spacer(flex: 3),
              // Sign in button
              if (authState.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    authState.error.toString().contains('network_error')
                        ? 'Network error — make sure you have a Google account\nadded in the device Settings, then try again.'
                        : 'Sign in failed. Please try again.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => ref.read(authProvider.notifier).signIn(),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.login, size: 20),
                  label: Text(isLoading ? 'Signing in...' : 'Continue with Google'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Signing in grants access to create and manage\nyour wedding spreadsheet.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.dustyRose.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.dustyRose),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ],
    );
  }
}
