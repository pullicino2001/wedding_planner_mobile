import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/team_member.dart';
import '../../providers/guests_provider.dart';
import '../../providers/vendors_provider.dart';
import '../../providers/checklist_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/brief_pdf_service.dart';

class TeamMemberBriefScreen extends ConsumerStatefulWidget {
  final TeamMember member;

  const TeamMemberBriefScreen({super.key, required this.member});

  @override
  ConsumerState<TeamMemberBriefScreen> createState() =>
      _TeamMemberBriefScreenState();
}

class _TeamMemberBriefScreenState
    extends ConsumerState<TeamMemberBriefScreen> {
  TeamMember get member => widget.member;
  bool _exportingPdf = false;

  // Build the plain-text brief for sharing
  String _buildBriefText(
    TeamMember member,
    List<dynamic> guests,
    List<dynamic> vendors,
    List<dynamic> checklistItems,
    String coupleNames,
  ) {
    final buf = StringBuffer();

    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('ROLE BRIEF — ${member.name.toUpperCase()}');
    if (member.roleTitle.isNotEmpty) buf.writeln(member.roleTitle);
    if (member.phone.isNotEmpty) buf.writeln('📞 ${member.phone}');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    for (final phase in AppConstants.dutyPhases) {
      final duties = member.dutiesForPhase(phase);
      if (duties.isEmpty) continue;
      buf.writeln();
      buf.writeln('${phase.toUpperCase()} DUTIES');
      for (final d in duties) {
        buf.writeln('• ${d.description}');
      }
    }

    // Items assigned to this person
    final myItems = checklistItems
        .where((i) =>
            i.personName.toLowerCase() == member.name.toLowerCase() &&
            i.personName.isNotEmpty)
        .toList();
    if (myItems.isNotEmpty) {
      buf.writeln();
      buf.writeln('YOUR ITEMS');
      final church = myItems.where((i) => i.destination == AppConstants.checklistChurch).toList();
      final venue = myItems.where((i) => i.destination == AppConstants.checklistVenue).toList();
      if (church.isNotEmpty) {
        buf.writeln('  To Church:');
        for (final i in church) {
          final inH = i.inHand ? '✓' : '✗';
          final pk = i.packed ? '✓' : '✗';
          buf.writeln('  • ${i.item}  [In Hand: $inH | Packed: $pk]');
        }
      }
      if (venue.isNotEmpty) {
        buf.writeln('  To Venue:');
        for (final i in venue) {
          final inH = i.inHand ? '✓' : '✗';
          final pk = i.packed ? '✓' : '✗';
          buf.writeln('  • ${i.item}  [In Hand: $inH | Packed: $pk]');
        }
      }
    }

    // Dietary requirements
    if (member.pullsDietary) {
      final confirmed =
          guests.where((g) => g.rsvpStatus == AppConstants.rsvpConfirmed).toList();
      final withDietary = confirmed
          .where((g) => g.dietary.isNotEmpty && g.dietary.toLowerCase() != 'standard')
          .toList();

      buf.writeln();
      buf.writeln('DIETARY REQUIREMENTS');
      buf.writeln('Total confirmed: ${confirmed.length}');
      if (withDietary.isEmpty) {
        buf.writeln('No special dietary requirements.');
      } else {
        // Group by dietary value
        final groups = <String, int>{};
        for (final g in withDietary) {
          final key = g.dietary.trim();
          groups[key] = (groups[key] ?? 0) + 1;
        }
        for (final entry in groups.entries) {
          buf.writeln('• ${entry.key}: ${entry.value}');
        }
      }
    }

    // Linked vendor
    if (member.linkedVendorCategory.isNotEmpty) {
      final linked = vendors
          .where((v) => v.category == member.linkedVendorCategory)
          .toList();
      if (linked.isNotEmpty) {
        buf.writeln();
        buf.writeln('LINKED VENDOR — ${member.linkedVendorCategory.toUpperCase()}');
        for (final v in linked) {
          buf.writeln('${v.name}');
          if (v.contactPerson.isNotEmpty) buf.writeln('Contact: ${v.contactPerson}');
          if (v.phone.isNotEmpty) buf.writeln('📞 ${v.phone}');
          if (v.email.isNotEmpty) buf.writeln('✉️  ${v.email}');
          if (v.notes.isNotEmpty) buf.writeln('Notes: ${v.notes}');
        }
      }
    }

    buf.writeln();
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('$coupleNames Wedding');
    return buf.toString().trim();
  }

  Future<void> _exportPdf(
    List<dynamic> guests,
    List<dynamic> vendors,
    List<dynamic> checklistItems,
    String coupleNames,
  ) async {
    setState(() => _exportingPdf = true);
    try {
      final bytes = await BriefPdfService().generate(
        member,
        guests.cast(),
        vendors.cast(),
        checklistItems.cast(),
        coupleNames,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${member.name.replaceAll(' ', '_')}_brief.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF export failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guestsState = ref.watch(guestsProvider);
    final vendorsState = ref.watch(vendorsProvider);
    final checklistState = ref.watch(checklistProvider);
    final settings = ref.watch(settingsProvider).value;

    final guests = guestsState.value ?? [];
    final vendors = vendorsState.value ?? [];
    final checklistItems = checklistState.value ?? [];
    final coupleNames = settings?.coupleNames ?? 'Wedding';

    final briefText = _buildBriefText(
        member, guests, vendors, checklistItems, coupleNames);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(member.name, style: AppTextStyles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            color: AppColors.tealVibrant,
            tooltip: 'Share as text',
            onPressed: () => Share.share(briefText,
                subject: 'Role Brief — ${member.name}'),
          ),
          IconButton(
            icon: _exportingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            color: AppColors.tealVibrant,
            tooltip: 'Export PDF',
            onPressed: _exportingPdf
                ? null
                : () => _exportPdf(guests, vendors, checklistItems, coupleNames),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGrad,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: AppTextStyles.displaySmall
                            .copyWith(color: Colors.white),
                      ),
                      if (member.roleTitle.isNotEmpty)
                        Text(
                          member.roleTitle,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white70),
                        ),
                      if (member.phone.isNotEmpty)
                        Text(
                          member.phone,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Duties per phase
          for (final phase in AppConstants.dutyPhases) ...[
            _DutiesSection(phase: phase, member: member),
          ],

          // My items
          _MyItemsSection(member: member, checklistItems: checklistItems),

          // Dietary
          if (member.pullsDietary)
            _DietarySection(guests: guests),

          // Linked vendor
          if (member.linkedVendorCategory.isNotEmpty)
            _VendorSection(
              category: member.linkedVendorCategory,
              vendors: vendors,
            ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Share.share(briefText,
                      subject: 'Role Brief — ${member.name}'),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share Text'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportingPdf
                      ? null
                      : () => _exportPdf(
                          guests, vendors, checklistItems, coupleNames),
                  icon: _exportingPdf
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DutiesSection extends StatelessWidget {
  final String phase;
  final TeamMember member;

  const _DutiesSection({required this.phase, required this.member});

  @override
  Widget build(BuildContext context) {
    final duties = member.dutiesForPhase(phase);
    if (duties.isEmpty) return const SizedBox.shrink();

    return _BriefCard(
      icon: phase == 'Church'
          ? Icons.church_outlined
          : phase == 'Venue'
              ? Icons.location_city_outlined
              : Icons.task_outlined,
      title: '$phase Duties',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: duties
            .map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(Icons.circle, size: 5,
                            color: AppColors.tealVibrant),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(d.description,
                            style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _MyItemsSection extends StatelessWidget {
  final TeamMember member;
  final List<dynamic> checklistItems;

  const _MyItemsSection(
      {required this.member, required this.checklistItems});

  @override
  Widget build(BuildContext context) {
    final myItems = checklistItems
        .where((i) =>
            i.personName.toLowerCase() == member.name.toLowerCase() &&
            i.personName.isNotEmpty)
        .toList();
    if (myItems.isEmpty) return const SizedBox.shrink();

    return _BriefCard(
      icon: Icons.inventory_2_outlined,
      title: 'Your Items',
      child: Column(
        children: myItems
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.item,
                                style: AppTextStyles.bodyMedium),
                            Text(
                              item.destination == AppConstants.checklistChurch
                                  ? 'To Church'
                                  : 'To Venue',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      _StatusChip(
                          label: 'In Hand', active: item.inHand),
                      const SizedBox(width: 6),
                      _StatusChip(label: 'Packed', active: item.packed),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? AppColors.tealVibrant.withAlpha(25)
            : AppColors.surfaceHi,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? AppColors.tealVibrant : AppColors.line,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: active ? AppColors.tealVibrant : AppColors.inkMute,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _DietarySection extends StatelessWidget {
  final List<dynamic> guests;

  const _DietarySection({required this.guests});

  @override
  Widget build(BuildContext context) {
    final confirmed =
        guests.where((g) => g.rsvpStatus == AppConstants.rsvpConfirmed).toList();
    final withDietary = confirmed
        .where((g) =>
            (g.dietary as String).isNotEmpty &&
            (g.dietary as String).toLowerCase() != 'standard')
        .toList();

    final groups = <String, int>{};
    for (final g in withDietary) {
      final key = (g.dietary as String).trim();
      groups[key] = (groups[key] ?? 0) + 1;
    }

    return _BriefCard(
      icon: Icons.restaurant_outlined,
      title: 'Dietary Requirements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total confirmed: ${confirmed.length}',
            style: AppTextStyles.bodyMedium,
          ),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('No special dietary requirements.',
                  style: AppTextStyles.bodySmall),
            )
          else
            ...groups.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.tealVibrant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(entry.key,
                              style: AppTextStyles.bodyMedium)),
                      Text(
                        '${entry.value}',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.tealVibrant),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _VendorSection extends StatelessWidget {
  final String category;
  final List<dynamic> vendors;

  const _VendorSection(
      {required this.category, required this.vendors});

  @override
  Widget build(BuildContext context) {
    final linked =
        vendors.where((v) => v.category == category).toList();
    if (linked.isEmpty) return const SizedBox.shrink();

    return _BriefCard(
      icon: Icons.store_outlined,
      title: 'Linked Vendor — $category',
      child: Column(
        children: linked
            .map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.name as String,
                          style: AppTextStyles.labelLarge),
                      if ((v.contactPerson as String).isNotEmpty)
                        _InfoRow(
                            icon: Icons.person_outline,
                            text: v.contactPerson as String),
                      if ((v.phone as String).isNotEmpty)
                        _InfoRow(
                            icon: Icons.phone_outlined,
                            text: v.phone as String),
                      if ((v.email as String).isNotEmpty)
                        _InfoRow(
                            icon: Icons.email_outlined,
                            text: v.email as String),
                      if ((v.notes as String).isNotEmpty)
                        _InfoRow(
                            icon: Icons.notes_outlined,
                            text: v.notes as String),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.inkMute),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _BriefCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _BriefCard(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.tealVibrant),
              const SizedBox(width: 8),
              Text(title.toUpperCase(),
                  style: AppTextStyles.sectionEyebrow
                      .copyWith(color: AppColors.tealVibrant)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
