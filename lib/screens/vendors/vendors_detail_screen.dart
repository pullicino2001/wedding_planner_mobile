import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/vendors_provider.dart';
import '../../models/vendor.dart';
import '../../widgets/vendors/vendor_card.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_card.dart';
import '../../widgets/common/empty_state.dart';

class VendorsDetailScreen extends ConsumerWidget {
  const VendorsDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Vendors', style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.read(vendorsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vendors/add'),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Add Vendor'),
      ),
      body: state.when(
        loading: () => const LoadingOverlay(message: 'Loading vendors…'),
        error: (e, _) => ErrorCard(
          message: e.toString(),
          onRetry: () => ref.read(vendorsProvider.notifier).refresh(),
        ),
        data: (vendors) {
          if (vendors.isEmpty) {
            return EmptyState(
              icon: Icons.store_outlined,
              title: 'No vendors yet',
              subtitle:
                  'Add your venue, caterer, photographer and all your wedding vendors here.',
              actionLabel: 'Add First Vendor',
              onAction: () => context.push('/vendors/add'),
            );
          }

          // Overdue / urgent vendors first
          final overdue = vendors.where((v) => v.isOverdue).toList();
          final upcoming = vendors
              .where((v) =>
                  !v.isOverdue &&
                  v.daysUntilNextDeadline != null &&
                  v.daysUntilNextDeadline! <= 14)
              .toList();
          final rest = vendors
              .where((v) => !v.isOverdue && !upcoming.contains(v))
              .toList();

          return RefreshIndicator(
            color: AppColors.dustyRose,
            onRefresh: () async =>
                ref.read(vendorsProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (overdue.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Needs Attention',
                    color: AppColors.danger,
                    icon: Icons.warning_amber_outlined,
                  ),
                  const SizedBox(height: 8),
                  ...overdue.map((v) => _vendorCard(context, ref, v)),
                  const SizedBox(height: 20),
                ],
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Upcoming Deadlines',
                    color: AppColors.warning,
                    icon: Icons.schedule_outlined,
                  ),
                  const SizedBox(height: 8),
                  ...upcoming.map((v) => _vendorCard(context, ref, v)),
                  const SizedBox(height: 20),
                ],
                if (rest.isNotEmpty) ...[
                  if (overdue.isNotEmpty || upcoming.isNotEmpty) ...[
                    const _SectionHeader(title: 'All Vendors'),
                    const SizedBox(height: 8),
                  ],
                  ...rest.map((v) => _vendorCard(context, ref, v)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _vendorCard(BuildContext context, WidgetRef ref, Vendor vendor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: VendorCard(
        vendor: vendor,
        onTap: () =>
            context.push('/vendors/view/${vendor.rowNumber}', extra: vendor),
        onDelete: () => _confirmDelete(context, ref, vendor),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Vendor vendor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove vendor?'),
        content: Text('Remove "${vendor.name}" from your vendor list?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(vendorsProvider.notifier).deleteVendor(vendor);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  final IconData? icon;

  const _SectionHeader({required this.title, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(
            color: color ?? AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
