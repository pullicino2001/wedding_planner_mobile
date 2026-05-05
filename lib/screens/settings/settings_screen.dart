import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Account & Settings', style: AppTextStyles.appBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Account card ─────────────────────────────────────────
          _SectionCard(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.tealVibrant.withAlpha(30),
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? Icon(Icons.person, size: 32,
                            color: AppColors.tealVibrant)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Not signed in',
                          style: AppTextStyles.cardTitle,
                        ),
                        if (user?.email != null) ...[
                          const SizedBox(height: 2),
                          Text(user!.email,
                              style: AppTextStyles.cardSubtitle),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: Text('Sign out',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.danger)),
                onTap: () => _confirmSignOut(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Wedding details ───────────────────────────────────────
          _SectionHeader(label: 'Wedding Details'),
          const SizedBox(height: 8),
          _SectionCard(
            children: [
              _InfoRow(
                icon: Icons.favorite_outline,
                label: 'Couple',
                value: settings?.coupleNames.isNotEmpty == true
                    ? settings!.coupleNames
                    : '—',
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Wedding date',
                value: settings?.weddingDate != null
                    ? DateFormat('d MMMM yyyy').format(settings!.weddingDate)
                    : '—',
              ),
              if (settings != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Text(
                    settings.daysUntilWedding > 0
                        ? '${settings.daysUntilWedding} days to go!'
                        : settings.daysUntilWedding == 0
                            ? 'Today is the day!'
                            : '${settings.daysUntilWedding.abs()} days ago',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.tealVibrant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  settings?.userRole == 'Bride'
                      ? Icons.favorite
                      : settings?.userRole == 'Groom'
                          ? Icons.diamond_outlined
                          : Icons.person_outline,
                  color: settings?.userRole == 'Bride'
                      ? AppColors.dustyRose
                      : settings?.userRole == 'Groom'
                          ? AppColors.steelBlue
                          : AppColors.textSecondary,
                ),
                title: Text('My role', style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary)),
                subtitle: Text(
                  settings?.userRole.isNotEmpty == true ? settings!.userRole : 'Not set',
                  style: AppTextStyles.bodyMedium,
                ),
                trailing: TextButton(
                  onPressed: () => _changeRole(context, settings),
                  child: const Text('Change'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Google Sheets ─────────────────────────────────────────
          _SectionHeader(label: 'Google Sheets'),
          const SizedBox(height: 8),
          _SectionCard(
            children: [
              // Main planner sheet
              _InfoRow(
                icon: Icons.table_chart_outlined,
                label: 'Wedding planner sheet',
                value: () {
                  final id = settings?.spreadsheetId ?? '';
                  return id.isNotEmpty
                      ? '${id.substring(0, 12.clamp(0, id.length))}…'
                      : 'Not set up';
                }(),
              ),
              if (settings?.spreadsheetUrl.isNotEmpty == true) ...[
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.copy_outlined,
                      color: AppColors.tealVibrant),
                  title: Text('Copy planner sheet link',
                      style: AppTextStyles.bodyMedium),
                  subtitle: Text('Open in Google Sheets on a browser',
                      style: AppTextStyles.bodySmall),
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: settings!.spreadsheetUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
              const Divider(height: 24),
              // Guest list sheet
              _InfoRow(
                icon: Icons.people_outline,
                label: 'Guest list sheet',
                value: settings?.hasGuestSheet == true
                    ? () {
                        final id = settings!.guestSheetId;
                        return '${id.substring(0, 12.clamp(0, id.length))}…';
                      }()
                    : 'Not configured',
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  settings?.hasGuestSheet == true
                      ? Icons.edit_outlined
                      : Icons.add_chart_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  settings?.hasGuestSheet == true
                      ? 'Change guest sheet'
                      : 'Set up guest sheet',
                  style: AppTextStyles.bodyMedium,
                ),
                subtitle: Text(
                  'Go to the Guests tab to create or link a sheet',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              if (settings?.hasGuestSheet == true &&
                  settings!.guestSheetUrl.isNotEmpty) ...[
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.copy_outlined,
                      color: AppColors.tealVibrant),
                  title: Text('Copy guest sheet link',
                      style: AppTextStyles.bodyMedium),
                  subtitle: Text('Open in Google Sheets on a browser',
                      style: AppTextStyles.bodySmall),
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: settings.guestSheetUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Change role ────────────────────────────────────────────────────────────
  Future<void> _changeRole(BuildContext context, dynamic settings) async {
    String selected = settings?.userRole ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('My role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoleTile(
                label: 'Bride',
                color: AppColors.dustyRose,
                selected: selected == 'Bride',
                onTap: () => setDialogState(() => selected = 'Bride'),
              ),
              const SizedBox(height: 12),
              _RoleTile(
                label: 'Groom',
                color: AppColors.steelBlue,
                selected: selected == 'Groom',
                onTap: () => setDialogState(() => selected = 'Groom'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selected.isEmpty ? null : () => Navigator.pop(ctx, true),
              child: Text('Save', style: TextStyle(color: AppColors.tealVibrant)),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(settingsProvider.notifier).saveRole(selected);
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'You\'ll need to sign back in to access your wedding data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign out',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            const Spacer(),
            if (selected) Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.tealVibrant),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
