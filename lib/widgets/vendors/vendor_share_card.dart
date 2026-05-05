import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/vendor.dart';

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

/// Standalone widget rendered off-screen and captured as an image for sharing.
/// Wrap in [RepaintBoundary] with a [GlobalKey] to capture.
class VendorShareCard extends StatelessWidget {
  final Vendor vendor;
  final bool showPricing;

  const VendorShareCard({
    super.key,
    required this.vendor,
    required this.showPricing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Gradient header ───────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.tealVibrant, AppColors.tealDeep],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branding
                  Row(
                    children: const [
                      Icon(Icons.favorite, size: 12, color: Colors.white60),
                      SizedBox(width: 6),
                      Text(
                        'WEDDING PLANNER',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Vendor name
                  Text(
                    vendor.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _categoryIcons[vendor.category] ??
                              Icons.store_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vendor.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact details
                  if (vendor.contactPerson.isNotEmpty ||
                      vendor.email.isNotEmpty ||
                      vendor.phone.isNotEmpty) ...[
                    _CardSection(
                      icon: Icons.person_outline,
                      title: 'CONTACT',
                      children: [
                        if (vendor.contactPerson.isNotEmpty)
                          _CardRow(
                              label: 'Name', value: vendor.contactPerson),
                        if (vendor.email.isNotEmpty)
                          _CardRow(label: 'Email', value: vendor.email),
                        if (vendor.phone.isNotEmpty)
                          _CardRow(label: 'Phone', value: vendor.phone),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Financials (only if showPricing)
                  if (showPricing) ...[
                    _CardSection(
                      icon: Icons.euro_outlined,
                      title: 'FINANCIALS',
                      children: [
                        _CardRow(
                          label: 'Total',
                          value: _currency.format(vendor.totalCost),
                          highlight: true,
                        ),
                        if (vendor.hasInstallments)
                          ...vendor.installments
                              .map((i) => _InstallmentCardRow(installment: i))
                        else ...[
                          if (vendor.depositDue != null)
                            _CardRow(
                              label: 'Deposit due',
                              value: _dateFormat.format(vendor.depositDue!),
                              statusLabel: vendor.depositPaid ? 'Paid' : null,
                              statusColor: AppColors.success,
                            ),
                          if (vendor.balanceDue != null)
                            _CardRow(
                              label: 'Balance due',
                              value: _dateFormat.format(vendor.balanceDue!),
                            ),
                        ],
                      ],
                    ),
                    if (vendor.notes.isNotEmpty) const SizedBox(height: 18),
                  ],

                  // Notes
                  if (vendor.notes.isNotEmpty) ...[
                    _CardSection(
                      icon: Icons.notes_outlined,
                      title: 'NOTES',
                      children: [
                        Text(
                          vendor.notes,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.favorite, size: 11, color: AppColors.tealVibrant),
                  SizedBox(width: 6),
                  Text(
                    'Shared from Wedding Planner',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Internal helpers ───────────────────────────────────────────────────────────

class _CardSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _CardSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColors.tealVibrant),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final String? statusLabel;
  final Color? statusColor;

  const _CardRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.statusLabel,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlight ? AppColors.tealVibrant : AppColors.textPrimary,
                fontSize: highlight ? 15 : 13,
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (statusLabel != null) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (statusColor ?? AppColors.success).withAlpha(28),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel!,
                style: TextStyle(
                  color: statusColor ?? AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InstallmentCardRow extends StatelessWidget {
  final Installment installment;
  const _InstallmentCardRow({required this.installment});

  @override
  Widget build(BuildContext context) {
    final color = installment.paid
        ? AppColors.success
        : installment.isOverdue
            ? AppColors.danger
            : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            installment.paid
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              installment.label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (installment.dueDate != null) ...[
            Text(
              _dateFormat.format(installment.dueDate!),
              style: TextStyle(color: color, fontSize: 11),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            _currency.format(installment.amount),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
