import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/budget_item.dart';
import '../../models/vendor.dart';
import '../../providers/budget_provider.dart';
import '../../providers/vendors_provider.dart';
import '../../widgets/budget/budget_row_tile.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_card.dart';
import '../../widgets/common/empty_state.dart';

final _currency = NumberFormat.currency(symbol: '€', decimalDigits: 0);

const _vendorCategoryIcons = <String, IconData>{
  'Venue': Icons.location_city_outlined,
  'Caterer': Icons.restaurant_outlined,
  'Photographer': Icons.camera_alt_outlined,
  'Videographer': Icons.videocam_outlined,
  'Florist': Icons.local_florist_outlined,
  'Band / DJ': Icons.music_note_outlined,
  'Baker': Icons.cake_outlined,
  'Hair & Makeup': Icons.face_retouching_natural_outlined,
  'Celebrant': Icons.favorite_border,
  'Transport': Icons.directions_car_outlined,
  'Stationery': Icons.mail_outline,
  'Accommodation': Icons.hotel_outlined,
  'Other': Icons.more_horiz,
};

class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);
    final vendorState = ref.watch(vendorsProvider);
    final combined = ref.watch(combinedBudgetStatsProvider);

    final isLoading = budgetState.isLoading || vendorState.isLoading;
    final hasError = budgetState.hasError;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Budget', style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.read(budgetProvider.notifier).refresh();
              ref.read(vendorsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/budget/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: isLoading
          ? const LoadingOverlay(message: 'Loading budget…')
          : hasError
              ? ErrorCard(
                  message: budgetState.error.toString(),
                  onRetry: () => ref.read(budgetProvider.notifier).refresh(),
                )
              : _buildBody(
                  context,
                  ref,
                  budgetItems: budgetState.value ?? [],
                  vendors: vendorState.value ?? [],
                  combined: combined,
                ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref, {
    required List<BudgetItem> budgetItems,
    required List<Vendor> vendors,
    required CombinedBudgetStats combined,
  }) {
    final hasVendors = vendors.isNotEmpty;
    final hasItems = budgetItems.isNotEmpty;

    if (!hasVendors && !hasItems) {
      return EmptyState(
        icon: Icons.attach_money,
        title: 'No budget yet',
        subtitle:
            'Add vendors with costs or tap "Add Item" to start tracking expenses.',
        actionLabel: 'Add Item',
        onAction: () => context.push('/budget/add'),
      );
    }

    // Group manual budget items by category
    final grouped = <String, List<BudgetItem>>{};
    for (final item in budgetItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return RefreshIndicator(
      color: AppColors.dustyRose,
      onRefresh: () async {
        ref.read(budgetProvider.notifier).refresh();
        ref.read(vendorsProvider.notifier).refresh();
      },
      child: CustomScrollView(
        slivers: [
          // ── Summary card ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _CombinedSummaryCard(stats: combined),
            ),
          ),

          // ── Vendor costs section ─────────────────────────────────────────
          if (hasVendors) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.store_outlined,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'VENDOR COSTS',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/home/vendors'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Manage vendors →',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.tealVibrant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Column(
                    children: [
                      ...vendors.asMap().entries.map((entry) {
                        final i = entry.key;
                        final v = entry.value;
                        return Column(
                          children: [
                            _VendorBudgetRow(
                              vendor: v,
                              onTap: () => context.push(
                                '/vendors/view/${v.rowNumber}',
                                extra: v,
                              ),
                            ),
                            if (i < vendors.length - 1)
                              const Divider(height: 1, indent: 16),
                          ],
                        );
                      }),
                      // Subtotal
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Text(
                              'Vendor total',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            if (combined.vendorPaid > 0) ...[
                              Text(
                                '${_currency.format(combined.vendorPaid)} paid',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('of', style: AppTextStyles.bodySmall),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _currency.format(combined.vendorTotal),
                              style: AppTextStyles.cardTitle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // ── Manual budget items by category ──────────────────────────────
          if (hasItems) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'OTHER EXPENSES',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final entry in grouped.entries) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(
                    entry.key,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Column(
                      children: entry.value
                          .map((item) => Column(
                                children: [
                                  BudgetRowTile(
                                    item: item,
                                    onTap: () => context.push(
                                        '/budget/edit/${item.rowNumber}',
                                        extra: item),
                                    onDelete: () =>
                                        _confirmDelete(context, ref, item),
                                  ),
                                  if (item != entry.value.last)
                                    const Divider(height: 1, indent: 16),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, BudgetItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.item}" from your budget?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(budgetProvider.notifier).deleteItem(item);
    }
  }
}

// ── Combined summary card ─────────────────────────────────────────────────────

class _CombinedSummaryCard extends StatelessWidget {
  final CombinedBudgetStats stats;
  const _CombinedSummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGrad,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x8C004D54),
            blurRadius: 38,
            spreadRadius: -14,
            offset: Offset(0, 18),
          ),
          BoxShadow(
            color: Color(0x4D004D54),
            blurRadius: 14,
            spreadRadius: -8,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Decorative blob
          Positioned(
            right: -60,
            bottom: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withAlpha(140),
                    Colors.white.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: -20,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB2EBF2).withAlpha(140),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL BUDGET',
                style: TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _currency.format(stats.totalActual),
                    style: const TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      fontSize: 44,
                      color: Colors.white,
                      letterSpacing: -0.9,
                      shadows: [
                        Shadow(
                          color: Color(0x59003E45),
                          blurRadius: 12,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'of ${_currency.format(stats.totalEstimated)}',
                    style: const TextStyle(
                      fontFamily: 'GoogleSans',
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Progress bar
              SizedBox(
                height: 8,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final progress = stats.spentProgress.clamp(0.0, 1.0);
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(46),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFB2EBF2), Colors.white],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vendors ${_currency.format(stats.vendorTotal)}  ·  '
                    'Other ${_currency.format(stats.manualEstimated)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11,
                        fontFamily: 'GoogleSans'),
                  ),
                  Text(
                    '${(stats.spentProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'GoogleSans',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ── Vendor row in budget list ─────────────────────────────────────────────────

class _VendorBudgetRow extends StatelessWidget {
  final Vendor vendor;
  final VoidCallback onTap;

  const _VendorBudgetRow({required this.vendor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final paid = vendorPaidAmount(vendor);
    final isOverdue = vendor.isOverdue;
    final days = vendor.daysUntilNextDeadline;

    // Payment status label + color
    String statusLabel;
    Color statusColor;
    if (vendor.totalCost == 0) {
      statusLabel = 'No cost set';
      statusColor = AppColors.textSecondary;
    } else if (vendor.hasInstallments) {
      final total = vendor.installments.length;
      final paidCount = vendor.installments.where((i) => i.paid).length;
      if (paidCount == total) {
        statusLabel = 'Paid in full';
        statusColor = AppColors.success;
      } else if (isOverdue) {
        statusLabel = 'Overdue';
        statusColor = AppColors.danger;
      } else if (days != null && days <= 14) {
        statusLabel = days == 0 ? 'Due today' : 'Due in $days days';
        statusColor = AppColors.warning;
      } else {
        statusLabel = '$paidCount/$total paid';
        statusColor = AppColors.textSecondary;
      }
    } else {
      if (vendor.depositPaid) {
        statusLabel = 'Deposit paid';
        statusColor = AppColors.tealVibrant;
      } else if (isOverdue) {
        statusLabel = 'Overdue';
        statusColor = AppColors.danger;
      } else {
        statusLabel = 'Pending';
        statusColor = AppColors.textSecondary;
      }
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryT,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _vendorCategoryIcons[vendor.category] ??
                    Icons.store_outlined,
                size: 18,
                color: AppColors.primaryTC,
              ),
            ),
            const SizedBox(width: 12),
            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vendor.name, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (paid > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${_currency.format(paid)} paid',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Total cost + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  vendor.totalCost > 0
                      ? _currency.format(vendor.totalCost)
                      : '—',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 2),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
