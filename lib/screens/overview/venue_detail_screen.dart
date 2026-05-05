import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/budget_provider.dart';
import '../../providers/guests_provider.dart';
import '../../providers/vendors_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/overview/progress_card.dart';

final _currency = NumberFormat.currency(symbol: '€', decimalDigits: 0);

class VenueDetailScreen extends ConsumerWidget {
  final String venue; // 'Church' or 'Reception'
  final Color accentColor;

  const VenueDetailScreen({
    super.key,
    required this.venue,
    required this.accentColor,
  });

  String get _imagePath => venue == 'Church'
      ? 'assets/images/church-01.png'
      : 'assets/images/reception-01.png';

  String get _venueName => venue == 'Church'
      ? "St. Augustine's"
      : 'Le Jardin Estate';

  String get _venueType => venue == 'Church' ? 'Ceremony' : 'Reception';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetStats = ref.watch(budgetStatsProvider);
    final guestStats = ref.watch(guestStatsProvider);
    final vendorStats = ref.watch(vendorStatsProvider);
    final taskStats = ref.watch(taskStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero app bar with image
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Full-width hero image
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: SizedBox(
                      height: 170,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(_imagePath, fit: BoxFit.cover),
                          // Gradient overlay
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0x2E00C2D6),
                                  Colors.transparent,
                                  const Color(0xA6003E45),
                                ],
                                stops: const [0.0, 0.3, 1.0],
                              ),
                            ),
                          ),
                          // Type label + venue name
                          Positioned(
                            left: 16,
                            bottom: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _venueType.toUpperCase(),
                                  style: AppTextStyles.sectionEyebrow.copyWith(
                                    color: Colors.white.withAlpha(200),
                                  ),
                                ),
                                Text(
                                  _venueName,
                                  style: const TextStyle(
                                    fontFamily: 'CormorantGaramond',
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 32,
                                    color: Colors.white,
                                    height: 1.05,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Back button
                Positioned(
                  top: 16 + MediaQuery.of(context).padding.top,
                  left: 28,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(210),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Section label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 18, height: 1, color: AppColors.ink),
                      const SizedBox(width: 10),
                      Text(
                        'FOUR PILLARS',
                        style: AppTextStyles.sectionEyebrow,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Tap to explore', style: AppTextStyles.displaySmall),
                ],
              ),
            ),
          ),

          // Module cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  ProgressCard(
                    title: 'Budget',
                    subtitle: budgetStats.itemCount == 0
                        ? 'No items yet'
                        : '${_currency.format(budgetStats.totalActual)} of '
                            '${_currency.format(budgetStats.totalEstimated)} spent',
                    progress: budgetStats.spentProgress,
                    progressColor: AppColors.progressBudget,
                    icon: Icons.euro_outlined,
                    onTap: () => context.go('/home/budget'),
                  ),
                  const SizedBox(height: 12),

                  ProgressCard(
                    title: 'RSVPs',
                    subtitle: guestStats.total == 0
                        ? 'No guests yet'
                        : '${guestStats.confirmed} of ${guestStats.total} confirmed',
                    progress: guestStats.confirmedProgress,
                    progressColor: AppColors.secondary,
                    icon: Icons.people_outline,
                    urgencyLabel: guestStats.pending > 0
                        ? '${guestStats.pending} pending'
                        : null,
                    onTap: () => context.go('/home/guests'),
                  ),
                  const SizedBox(height: 12),

                  ProgressCard(
                    title: 'Vendors',
                    subtitle: vendorStats.total == 0
                        ? 'No vendors yet'
                        : '${vendorStats.booked} of ${vendorStats.total} booked',
                    progress: vendorStats.bookedProgress,
                    progressColor: AppColors.accent,
                    icon: Icons.store_outlined,
                    urgencyLabel: vendorStats.overdueCount > 0
                        ? '${vendorStats.overdueCount} overdue'
                        : null,
                    onTap: () => context.go('/home/vendors'),
                  ),
                  const SizedBox(height: 12),

                  ProgressCard(
                    title: 'Tasks',
                    subtitle: taskStats.total == 0
                        ? 'No tasks yet'
                        : '${taskStats.done} of ${taskStats.total} complete',
                    progress: taskStats.doneProgress,
                    progressColor: AppColors.progressTasks,
                    icon: Icons.checklist_outlined,
                    urgencyLabel: taskStats.overdue > 0
                        ? '${taskStats.overdue} overdue'
                        : null,
                    onTap: () => context.go('/home/timeline'),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
