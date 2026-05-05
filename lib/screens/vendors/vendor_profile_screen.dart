import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/vendor.dart';
import '../../providers/budget_provider.dart';
import '../../widgets/vendors/vendor_share_card.dart';

final _currency = NumberFormat.currency(symbol: '€', decimalDigits: 0);
final _dateFormat = DateFormat('d MMM y');

const _categoryIcons = <String, IconData>{
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

class VendorProfileScreen extends ConsumerStatefulWidget {
  final Vendor vendor;
  const VendorProfileScreen({super.key, required this.vendor});

  @override
  ConsumerState<VendorProfileScreen> createState() =>
      _VendorProfileScreenState();
}

class _VendorProfileScreenState extends ConsumerState<VendorProfileScreen> {
  // Keys for the off-screen share card renders
  final _withPricingKey = GlobalKey();
  final _withoutPricingKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;
    final combined = ref.watch(combinedBudgetStatsProvider);
    final budgetShare = combined.totalEstimated > 0
        ? (vendor.totalCost / combined.totalEstimated).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(vendor.name, style: AppTextStyles.appBarTitle),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
            onPressed: () =>
                context.push('/vendors/edit/${vendor.rowNumber}', extra: vendor),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Main scrollable view ─────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(vendor: vendor),
                const SizedBox(height: 16),

                // Contact section
                if (vendor.contactPerson.isNotEmpty ||
                    vendor.email.isNotEmpty ||
                    vendor.phone.isNotEmpty) ...[
                  _ProfileSection(
                    title: 'Contact',
                    icon: Icons.person_outline,
                    children: [
                      if (vendor.contactPerson.isNotEmpty)
                        _DetailRow(
                            label: 'Contact person',
                            value: vendor.contactPerson),
                      if (vendor.email.isNotEmpty)
                        _DetailRow(label: 'Email', value: vendor.email),
                      if (vendor.phone.isNotEmpty)
                        _DetailRow(label: 'Phone', value: vendor.phone),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Financials section
                _ProfileSection(
                  title: 'Financials',
                  icon: Icons.euro_outlined,
                  children: [
                    _DetailRow(
                      label: 'Total cost',
                      value: _currency.format(vendor.totalCost),
                    ),
                    if (vendor.hasInstallments) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Payment schedule',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      ...vendor.installments
                          .map((i) => _InstallmentDetailRow(installment: i)),
                    ] else ...[
                      if (vendor.depositDue != null)
                        _DetailRow(
                          label: 'Deposit due',
                          value: _dateFormat.format(vendor.depositDue!),
                          trailing: vendor.depositPaid
                              ? _Badge(
                                  label: 'Paid',
                                  color: AppColors.success,
                                )
                              : vendor.isOverdue
                                  ? _Badge(
                                      label: 'Overdue',
                                      color: AppColors.danger,
                                    )
                                  : null,
                        ),
                      if (vendor.balanceDue != null)
                        _DetailRow(
                          label: 'Balance due',
                          value: _dateFormat.format(vendor.balanceDue!),
                        ),
                    ],
                  ],
                ),

                // Notes section
                if (vendor.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ProfileSection(
                    title: 'Notes',
                    icon: Icons.notes_outlined,
                    children: [
                      Text(vendor.notes, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ],

                // Budget impact
                if (vendor.totalCost > 0 && combined.totalEstimated > 0) ...[
                  const SizedBox(height: 16),
                  _BudgetImpactRow(
                    vendor: vendor,
                    share: budgetShare,
                    totalBudget: combined.totalEstimated,
                    onViewBudget: () => context.go('/home/budget'),
                  ),
                ],
              ],
            ),
          ),

          // ── Off-screen share card renders ────────────────────────────────
          // These are painted off-screen via Transform.translate so
          // RepaintBoundary.toImage() can capture them without affecting the UI.
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _OffScreenCard(
                    cardKey: _withPricingKey,
                    vendor: vendor,
                    showPricing: true,
                  ),
                  _OffScreenCard(
                    cardKey: _withoutPricingKey,
                    vendor: vendor,
                    showPricing: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sharing ? null : () => _showShareSheet(context),
        backgroundColor: AppColors.tealVibrant,
        icon: _sharing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.ios_share_outlined),
        label: Text(_sharing ? 'Preparing…' : 'Share'),
      ),
    );
  }

  // ── Share bottom sheet ────────────────────────────────────────────────────

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Share vendor card', style: AppTextStyles.cardTitle),
            const SizedBox(height: 6),
            Text(
              'Pick what to include in the shared image.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            _ShareOption(
              icon: Icons.attach_money,
              iconColor: AppColors.tealVibrant,
              title: 'Include pricing',
              subtitle: 'Shows total cost and payment schedule',
              onTap: () {
                Navigator.pop(ctx);
                _doShare(showPricing: true);
              },
            ),
            const SizedBox(height: 10),
            _ShareOption(
              icon: Icons.money_off_outlined,
              iconColor: AppColors.warmGrey,
              title: 'Without pricing',
              subtitle: 'Contact and booking details only',
              onTap: () {
                Navigator.pop(ctx);
                _doShare(showPricing: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Capture & share ───────────────────────────────────────────────────────

  Future<void> _doShare({required bool showPricing}) async {
    setState(() => _sharing = true);
    try {
      final key = showPricing ? _withPricingKey : _withoutPricingKey;
      final bytes = await _captureKey(key);
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not create image. Try again.')),
          );
        }
        return;
      }
      if (!mounted) return;

      final dir = await getTemporaryDirectory();
      final label = showPricing ? 'full' : 'no_price';
      final file =
          File('${dir.path}/vendor_${widget.vendor.id}_$label.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: '${widget.vendor.name} — Vendor Details',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<Uint8List?> _captureKey(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (e) {
      debugPrint('VendorProfileScreen capture error: $e');
      return null;
    }
  }
}

// ── Off-screen render helper ─────────────────────────────────────────────────

/// Renders the share card off-screen (10 000 px below viewport) so that
/// RepaintBoundary.toImage() can capture it without affecting the visible UI.
class _OffScreenCard extends StatelessWidget {
  final GlobalKey cardKey;
  final Vendor vendor;
  final bool showPricing;

  const _OffScreenCard({
    required this.cardKey,
    required this.vendor,
    required this.showPricing,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 10000),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: cardKey,
              child: VendorShareCard(
                vendor: vendor,
                showPricing: showPricing,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Profile UI components ─────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final Vendor vendor;
  const _HeaderCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final isOverdue = vendor.isOverdue;
    final days = vendor.daysUntilNextDeadline;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tealVibrant, AppColors.tealDeep],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcons[vendor.category] ?? Icons.store_outlined,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendor.category,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOverdue)
                _StatusChip(label: 'Overdue', color: AppColors.danger)
              else if (days != null && days <= 14)
                _StatusChip(
                  label: days == 0 ? 'Due today' : '$days days',
                  color: AppColors.warning,
                ),
            ],
          ),
          if (vendor.totalCost > 0) ...[
            const SizedBox(height: 18),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 18),
            Text(
              _currency.format(vendor.totalCost),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Total cost',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.tealVibrant),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _DetailRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _InstallmentDetailRow extends StatelessWidget {
  final Installment installment;
  const _InstallmentDetailRow({required this.installment});

  @override
  Widget build(BuildContext context) {
    final color = installment.paid
        ? AppColors.success
        : installment.isOverdue
            ? AppColors.danger
            : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            installment.paid
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              installment.label,
              style: AppTextStyles.bodyMedium.copyWith(color: color),
            ),
          ),
          if (installment.dueDate != null) ...[
            Text(
              _dateFormat.format(installment.dueDate!),
              style: AppTextStyles.bodySmall.copyWith(color: color),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            _currency.format(installment.amount),
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Budget impact widget ──────────────────────────────────────────────────────

class _BudgetImpactRow extends StatelessWidget {
  final Vendor vendor;
  final double share;
  final double totalBudget;
  final VoidCallback onViewBudget;

  const _BudgetImpactRow({
    required this.vendor,
    required this.share,
    required this.totalBudget,
    required this.onViewBudget,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (share * 100).toStringAsFixed(0);
    final currency = NumberFormat.currency(symbol: '€', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline,
                  size: 16, color: AppColors.tealVibrant),
              const SizedBox(width: 8),
              Text(
                'Budget Impact',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewBudget,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View budget →',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.tealVibrant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$pct% of total budget',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currency.format(vendor.totalCost)} of '
                      '${currency.format(totalBudget)} total',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              // Mini bar showing this vendor's share
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 8,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.tealVibrant),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
