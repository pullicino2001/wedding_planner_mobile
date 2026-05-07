import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/role_templates.dart';
import '../../models/running_order_item.dart';
import '../../models/team_member.dart';
import '../../models/checklist_item.dart';
import '../../providers/running_order_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/checklist_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_card.dart';
import '../../widgets/common/empty_state.dart';

class DayOfScreen extends ConsumerStatefulWidget {
  const DayOfScreen({super.key});

  @override
  ConsumerState<DayOfScreen> createState() => _DayOfScreenState();
}

class _DayOfScreenState extends ConsumerState<DayOfScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _onFab() {
    switch (_tab.index) {
      case 0:
        context.push('/dayof/running-order/add');
      case 1:
        context.push('/dayof/team/add');
      case 2:
        context.push('/dayof/checklist/add');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Day Of', style: AppTextStyles.appBarTitle),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.tealVibrant,
          labelColor: AppColors.tealVibrant,
          unselectedLabelColor: AppColors.inkMute,
          labelStyle: AppTextStyles.labelLarge,
          unselectedLabelStyle: AppTextStyles.labelSmall,
          tabs: const [
            Tab(text: 'Schedule'),
            Tab(text: 'Team'),
            Tab(text: 'Checklist'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _ScheduleTab(),
          _TeamTab(),
          _ChecklistTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFab,
        backgroundColor: AppColors.tealVibrant,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── Schedule Tab ─────────────────────────────────────────────────────────────

class _ScheduleTab extends ConsumerWidget {
  const _ScheduleTab();

  static Color _phaseColor(String phase) {
    switch (phase) {
      case 'Getting Ready':
        return AppColors.steelBlue;
      case 'Church':
        return AppColors.warning;
      case 'Reception':
        return AppColors.tealVibrant;
      default:
        return AppColors.inkMute;
    }
  }

  static IconData _phaseIcon(String phase) {
    switch (phase) {
      case 'Getting Ready':
        return Icons.wb_sunny_outlined;
      case 'Church':
        return Icons.church_outlined;
      case 'Reception':
        return Icons.celebration_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(runningOrderProvider);

    return state.when(
      loading: () => const LoadingOverlay(),
      error: (e, _) => ErrorCard(message: e.toString()),
      data: (items) {
        // Group by phase, sort by time within each phase
        final groups = <String, List<RunningOrderItem>>{};
        for (final phase in AppConstants.runningOrderPhases) {
          final phaseItems = items
              .where((i) => i.phase == phase)
              .toList()
            ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
          groups[phase] = phaseItems;
        }
        final other = items
            .where((i) => !AppConstants.runningOrderPhases.contains(i.phase))
            .toList()
          ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
        if (other.isNotEmpty) groups['Other'] = other;

        final hasAny = groups.values.any((list) => list.isNotEmpty);

        return RefreshIndicator(
          color: AppColors.tealVibrant,
          onRefresh: () => ref.read(runningOrderProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              if (!hasAny)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.schedule_outlined,
                    title: 'No schedule yet',
                    subtitle: 'Add time slots for the day — ceremony, reception, key moments.',
                  ),
                ),
              for (final entry in groups.entries) ...[
                _PhaseTable(
                  phase: entry.key,
                  items: entry.value,
                  color: _phaseColor(entry.key),
                  icon: _phaseIcon(entry.key),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PhaseTable extends ConsumerWidget {
  final String phase;
  final List<RunningOrderItem> items;
  final Color color;
  final IconData icon;

  const _PhaseTable({
    required this.phase,
    required this.items,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase banner
          Container(
            color: color.withAlpha(22),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    phase.toUpperCase(),
                    style: AppTextStyles.sectionEyebrow.copyWith(color: color),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/dayof/running-order/add'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 13, color: color),
                      const SizedBox(width: 2),
                      Text(
                        'Add',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rows
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                'No ${phase.toLowerCase()} events yet',
                style: AppTextStyles.bodySmall,
              ),
            )
          else
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(height: 1, color: AppColors.line),
              _ScheduleRow(item: items[i], color: color),
            ],
        ],
      ),
    );
  }
}

class _ScheduleRow extends ConsumerWidget {
  final RunningOrderItem item;
  final Color color;

  const _ScheduleRow({required this.item, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger.withAlpha(25),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete event?'),
            content: Text(item.description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) =>
          ref.read(runningOrderProvider.notifier).deleteItem(item),
      child: InkWell(
        onTap: () => context.push('/dayof/running-order/edit/${item.id}',
            extra: item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  item.time.isEmpty ? '—' : item.time,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: item.notes.isNotEmpty ? 36 : 20,
                color: AppColors.line,
                margin: const EdgeInsets.only(right: 12),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.description, style: AppTextStyles.bodyMedium),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.notes, style: AppTextStyles.bodySmall),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.inkMute),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Team Tab ─────────────────────────────────────────────────────────────────

class _TeamTab extends ConsumerWidget {
  const _TeamTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamProvider);

    return state.when(
      loading: () => const LoadingOverlay(),
      error: (e, _) => ErrorCard(message: e.toString()),
      data: (members) {
        // Build a lookup: roleTitle (lowercase) → list of members
        final byRole = <String, List<TeamMember>>{};
        for (final m in members) {
          final key = m.roleTitle.trim().toLowerCase();
          byRole.putIfAbsent(key, () => []).add(m);
        }

        // Members whose role doesn't match any template
        final templateTitles = kRoleTemplates
            .map((t) => t.title.toLowerCase())
            .toSet();
        final custom = members
            .where((m) => !templateTitles.contains(m.roleTitle.trim().toLowerCase()))
            .toList();

        return RefreshIndicator(
          color: AppColors.tealVibrant,
          onRefresh: () => ref.read(teamProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              for (final category in kRoleCategories) ...[
                _CategoryHeader(label: category),
                const SizedBox(height: 8),
                for (final template in kRoleTemplates.where(
                    (t) => t.category == category)) ...[
                  _RoleSlot(
                    template: template,
                    assigned: byRole[template.title.toLowerCase()] ?? [],
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
              ],
              if (custom.isNotEmpty) ...[
                _CategoryHeader(label: 'Other'),
                const SizedBox(height: 8),
                for (final member in custom) ...[
                  _AssignedMemberTile(member: member),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
              ],
              // Custom role add button
              OutlinedButton.icon(
                onPressed: () => context.push('/dayof/team/add'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add a custom role'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.inkMute,
                  side: const BorderSide(color: AppColors.line),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String label;
  const _CategoryHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.sectionEyebrow.copyWith(
        color: AppColors.inkMute,
        letterSpacing: 1.1,
      ),
    );
  }
}

/// A role slot shows:
/// - Unassigned: dashed border, muted, role title + first duty hint, "Assign" button
/// - Assigned (1+): solid card per person; for allowMultiple also shows "Add another"
class _RoleSlot extends ConsumerWidget {
  final RoleTemplate template;
  final List<TeamMember> assigned;

  const _RoleSlot({required this.template, required this.assigned});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (assigned.isEmpty) {
      return _UnassignedSlot(template: template);
    }

    return Column(
      children: [
        for (final member in assigned) ...[
          _AssignedMemberTile(member: member, template: template),
          if (member != assigned.last) const SizedBox(height: 6),
        ],
        if (template.allowMultiple) ...[
          const SizedBox(height: 6),
          _AddAnotherButton(template: template),
        ],
      ],
    );
  }
}

class _UnassignedSlot extends StatelessWidget {
  final RoleTemplate template;
  const _UnassignedSlot({required this.template});

  @override
  Widget build(BuildContext context) {
    final dutyHint = template.defaultDuties.isNotEmpty
        ? template.defaultDuties.first.description
        : null;

    return GestureDetector(
      onTap: () => context.push('/dayof/team/add', extra: template),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.line,
            strokeAlign: BorderSide.strokeAlignInside,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceHi,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(template.icon, size: 18, color: AppColors.inkMute),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.title,
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.inkSoft)),
                  if (dutyHint != null)
                    Text(
                      dutyHint,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tealVibrant.withAlpha(18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.tealVibrant.withAlpha(60)),
              ),
              child: Text(
                'Assign',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.tealVibrant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignedMemberTile extends ConsumerWidget {
  final TeamMember member;
  final RoleTemplate? template;

  const _AssignedMemberTile({required this.member, this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(member.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(30),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove person?'),
          content: Text('Remove ${member.name} from the team?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text('Remove', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      ),
      onDismissed: (_) =>
          ref.read(teamProvider.notifier).deleteMember(member),
      child: GestureDetector(
        onTap: () =>
            context.push('/dayof/team/brief/${member.id}', extra: member),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGrad,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: AppTextStyles.labelLarge),
                    Text(
                      member.roleTitle.isNotEmpty
                          ? member.roleTitle
                          : 'No role title',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (member.pullsDietary)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.restaurant_outlined,
                          size: 13, color: AppColors.tealVibrant),
                    ),
                  if (member.linkedVendorCategory.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.store_outlined,
                          size: 13, color: AppColors.tealVibrant),
                    ),
                  GestureDetector(
                    onTap: () => context.push(
                        '/dayof/team/edit/${member.id}',
                        extra: member),
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.inkMute),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddAnotherButton extends StatelessWidget {
  final RoleTemplate template;
  const _AddAnotherButton({required this.template});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dayof/team/add', extra: template),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: AppColors.tealVibrant),
            const SizedBox(width: 4),
            Text(
              'Add another ${template.title}',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.tealVibrant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Checklist Tab ────────────────────────────────────────────────────────────

class _ChecklistTab extends ConsumerStatefulWidget {
  const _ChecklistTab();

  @override
  ConsumerState<_ChecklistTab> createState() => _ChecklistTabState();
}

class _ChecklistTabState extends ConsumerState<_ChecklistTab> {
  String _dest = AppConstants.checklistChurch;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checklistProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: AppConstants.checklistChurch,
                label: Text('Church'),
                icon: Icon(Icons.church_outlined, size: 16),
              ),
              ButtonSegment(
                value: AppConstants.checklistVenue,
                label: Text('Venue'),
                icon: Icon(Icons.location_city_outlined, size: 16),
              ),
            ],
            selected: {_dest},
            onSelectionChanged: (s) => setState(() => _dest = s.first),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.when(
            loading: () => const LoadingOverlay(),
            error: (e, _) => ErrorCard(message: e.toString()),
            data: (items) {
              final filtered =
                  items.where((i) => i.destination == _dest).toList();
              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.checklist_outlined,
                  title: 'Nothing here yet',
                  subtitle: _dest == AppConstants.checklistChurch
                      ? 'Add items to bring to the church.'
                      : 'Add items to bring to the venue.',
                );
              }

              final inHandCount =
                  filtered.where((i) => i.inHand).length;
              final packedCount =
                  filtered.where((i) => i.packed).length;

              return RefreshIndicator(
                color: AppColors.tealVibrant,
                onRefresh: () =>
                    ref.read(checklistProvider.notifier).refresh(),
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          _CheckStat(
                              label: 'In Hand',
                              count: inHandCount,
                              total: filtered.length,
                              color: AppColors.success),
                          const SizedBox(width: 12),
                          _CheckStat(
                              label: 'Packed',
                              count: packedCount,
                              total: filtered.length,
                              color: AppColors.tealVibrant),
                        ],
                      ),
                    ),
                    ...filtered.map((item) => _ChecklistTile(item: item)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CheckStat extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _CheckStat(
      {required this.label,
      required this.count,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: color),
            const SizedBox(width: 6),
            Text('$count/$total $label',
                style: AppTextStyles.labelSmall
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ChecklistTile extends ConsumerWidget {
  final ChecklistItem item;
  const _ChecklistTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(checklistProvider.notifier);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withAlpha(30),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      onDismissed: (_) => notifier.deleteItem(item),
      child: GestureDetector(
        onTap: () => context.push(
            '/dayof/checklist/edit/${item.id}',
            extra: item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.item, style: AppTextStyles.bodyMedium),
                    if (item.personName.isNotEmpty)
                      Text(item.personName,
                          style: AppTextStyles.bodySmall),
                    if (item.notes.isNotEmpty)
                      Text(item.notes, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              _CheckBox(
                label: 'In Hand',
                value: item.inHand,
                onTap: () => notifier.toggleInHand(item),
              ),
              const SizedBox(width: 8),
              _CheckBox(
                label: 'Packed',
                value: item.packed,
                onTap: () => notifier.togglePacked(item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onTap;

  const _CheckBox(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: value
                  ? AppColors.tealVibrant
                  : AppColors.surfaceHi,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AppColors.tealVibrant : AppColors.line,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}
