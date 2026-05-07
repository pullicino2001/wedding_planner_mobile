import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/settings_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/guests_provider.dart';
import '../../providers/vendors_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../models/budget_item.dart';
import '../../models/guest.dart';
import '../../models/vendor.dart';
import '../../models/task_item.dart';
import '../../widgets/overview/countdown_banner.dart';
import '../../widgets/common/loading_overlay.dart';
import 'venue_detail_screen.dart';

final _currency = NumberFormat.compactCurrency(symbol: '€', decimalDigits: 0);

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterCtrl;
  late Animation<double> _enterFade;
  late Animation<Offset> _enterSlide;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _enterFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: Curves.easeOut,
    );
    _enterSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/church-01.png'), context);
    precacheImage(const AssetImage('assets/images/reception-01.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value;
    final budgetStats = ref.watch(budgetStatsProvider);
    final guestStats = ref.watch(guestStatsProvider);
    final vendorStats = ref.watch(vendorStatsProvider);
    final taskStats = ref.watch(taskStatsProvider);

    final isLoading = ref.watch(budgetProvider).isLoading ||
        ref.watch(guestsProvider).isLoading ||
        ref.watch(vendorsProvider).isLoading ||
        ref.watch(tasksProvider).isLoading;

    final overallProgress = (budgetStats.spentProgress +
            guestStats.confirmedProgress +
            vendorStats.bookedProgress +
            taskStats.doneProgress) /
        4;

    final totalUrgency = (guestStats.pending > 0 ? 1 : 0) +
        (vendorStats.overdueCount > 0 ? 1 : 0) +
        (taskStats.overdue > 0 ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          settings?.coupleNames.isNotEmpty == true
              ? settings!.coupleNames
              : 'Overview',
          style: AppTextStyles.appBarTitle,
        ),
        actions: [
          _PillIconButton(
            icon: Icons.refresh_outlined,
            onPressed: () {
              ref.read(budgetProvider.notifier).refresh();
              ref.read(guestsProvider.notifier).refresh();
              ref.read(vendorsProvider.notifier).refresh();
              ref.read(tasksProvider.notifier).refresh();
            },
          ),
          _PillIconButton(
            icon: Icons.account_circle_outlined,
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const LoadingOverlay(message: 'Loading your wedding data…')
          : FadeTransition(
              opacity: _enterFade,
              child: SlideTransition(
                position: _enterSlide,
                child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.read(budgetProvider.notifier).refresh();
                ref.read(guestsProvider.notifier).refresh();
                ref.read(vendorsProvider.notifier).refresh();
                ref.read(tasksProvider.notifier).refresh();
              },
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Countdown hero
                  if (settings != null)
                    CountdownBanner(
                      daysUntilWedding: settings.daysUntilWedding,
                      coupleNames: settings.coupleNames,
                      plannedProgress: overallProgress,
                    ),

                  const SizedBox(height: 24),
                  _SectionLabel(
                    eyebrow: 'Your day · in two acts',
                    title: 'Two venues, one story',
                    subtitle: 'Tap a venue to step into the details.',
                  ),

                  // Church venue card
                  _VenueCard(
                    venue: 'The Church',
                    imagePath: 'assets/images/church-01.png',
                    progress: overallProgress,
                    urgencyCount: totalUrgency,
                    destination: VenueDetailScreen(
                      venue: 'Church',
                      accentColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Reception venue card
                  _VenueCard(
                    venue: 'The Reception',
                    imagePath: 'assets/images/reception-01.png',
                    progress: overallProgress,
                    urgencyCount: totalUrgency,
                    destination: VenueDetailScreen(
                      venue: 'Reception',
                      accentColor: AppColors.primaryDeep,
                    ),
                  ),

                  const SizedBox(height: 20),
                  // At a glance pills
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      children: [
                        Container(
                            width: 18, height: 1, color: AppColors.ink),
                        const SizedBox(width: 10),
                        Text('At a glance',
                            style: AppTextStyles.sectionEyebrow),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StatPillRow(
                    budgetStats: budgetStats,
                    guestStats: guestStats,
                    vendorStats: vendorStats,
                    taskStats: taskStats,
                  ),

                  // Google Sheets note
                  if (settings?.spreadsheetUrl.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHi,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.table_chart_outlined,
                                size: 16,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your data lives in Google Sheets — always accessible, always yours.',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.inkSoft),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

// ── Pill icon button in appbar ────────────────────────────────────────────────

class _PillIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _PillIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.inkSoft),
      ),
    );
  }
}

// ── Section label with hairline eyebrow ──────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  const _SectionLabel(
      {required this.eyebrow, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 18, height: 1, color: AppColors.ink),
              const SizedBox(width: 10),
              Text(eyebrow.toUpperCase(), style: AppTextStyles.sectionEyebrow),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: AppTextStyles.displaySmall),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTextStyles.cardSubtitle),
          ],
        ],
      ),
    );
  }
}

// ── Venue card with image hero + tonal footer ─────────────────────────────────

class _VenueCard extends StatelessWidget {
  final String venue;
  final String imagePath;
  final double progress;
  final int urgencyCount;
  final Widget destination;

  const _VenueCard({
    required this.venue,
    required this.imagePath,
    required this.progress,
    required this.urgencyCount,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: OpenContainer(
        transitionDuration: const Duration(milliseconds: 320),
        transitionType: ContainerTransitionType.fadeThrough,
        openColor: AppColors.background,
        closedColor: AppColors.surface,
        closedElevation: 0,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppColors.line),
        ),
        openBuilder: (context, _) => destination,
        closedBuilder: (context, openContainer) => GestureDetector(
          onTap: openContainer,
          child: Column(
            children: [
              // Image section with inner padding
              Padding(
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 132,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RepaintBoundary(
                          child: Image.asset(imagePath, fit: BoxFit.cover),
                        ),
                        // Teal gradient overlay
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                const Color(0x8C003E45),
                              ],
                              stops: const [0.3, 1.0],
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0x3300C2D6),
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.55],
                            ),
                          ),
                        ),
                        // Urgency pill
                        if (urgencyCount > 0)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 3)
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$urgencyCount need attention',
                                    style: AppTextStyles.urgencyBadge.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Venue name over image
                        Positioned(
                          left: 14,
                          bottom: 10,
                          child: Text(
                            venue,
                            style: const TextStyle(
                              fontFamily: 'CormorantGaramond',
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Color(0x59000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Tonal footer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    ProgressDial(progress: progress),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OVERALL PLANNING',
                            style: AppTextStyles.sectionEyebrow
                                .copyWith(fontSize: 9),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}% complete · '
                            '${progress < 0.5 ? 'getting started' : 'on track'}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryT,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.primaryTC,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── At-a-glance stat pills ────────────────────────────────────────────────────

class _StatPillRow extends StatelessWidget {
  final BudgetStats budgetStats;
  final GuestStats guestStats;
  final VendorStats vendorStats;
  final TaskStats taskStats;

  const _StatPillRow({
    required this.budgetStats,
    required this.guestStats,
    required this.vendorStats,
    required this.taskStats,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatData(
        label: 'Budget',
        value: _currency.format(budgetStats.totalActual),
        tail: '/ ${_currency.format(budgetStats.totalEstimated)}',
        bg: AppColors.primaryT,
      ),
      _StatData(
        label: 'Guests',
        value: '${guestStats.confirmed}',
        tail: '/ ${guestStats.total}',
        bg: AppColors.secondaryT,
      ),
      _StatData(
        label: 'Vendors',
        value: '${vendorStats.booked}',
        tail: '/ ${vendorStats.total}',
        bg: AppColors.surfaceHi,
      ),
      _StatData(
        label: 'Tasks',
        value: '${taskStats.done}',
        tail: '/ ${taskStats.total}',
        bg: AppColors.surfaceHi,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: items.map((d) => _StatPill(data: d)).toList(),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final String tail;
  final Color bg;
  const _StatData(
      {required this.label,
      required this.value,
      required this.tail,
      required this.bg});
}

class _StatPill extends StatelessWidget {
  final _StatData data;
  const _StatPill({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      constraints: const BoxConstraints(minWidth: 86),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label.toUpperCase(),
            style: AppTextStyles.sectionEyebrow.copyWith(fontSize: 9),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 3),
              Text(data.tail, style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
