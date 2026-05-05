import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
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
      backgroundColor: AppColors.background,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(runningOrderProvider);

    return state.when(
      loading: () => const LoadingOverlay(),
      error: (e, _) => ErrorCard(message: e.toString()),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.schedule_outlined,
            title: 'No schedule yet',
            subtitle: 'Add time slots for the day — ceremony, reception, key moments.',
          );
        }

        // Group by phase, sort by time within each group
        final groups = <String, List<RunningOrderItem>>{};
        for (final phase in AppConstants.runningOrderPhases) {
          final phaseItems = items
              .where((i) => i.phase == phase)
              .toList()
            ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
          if (phaseItems.isNotEmpty) groups[phase] = phaseItems;
        }
        // Catch any items with unrecognised phases
        final other = items
            .where((i) => !AppConstants.runningOrderPhases.contains(i.phase))
            .toList()
          ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
        if (other.isNotEmpty) groups['Other'] = other;

        return RefreshIndicator(
          color: AppColors.tealVibrant,
          onRefresh: () => ref.read(runningOrderProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              for (final entry in groups.entries) ...[
                _PhaseHeader(phase: entry.key),
                ...entry.value.map((item) => _ScheduleTile(item: item)),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PhaseHeader extends StatelessWidget {
  final String phase;
  const _PhaseHeader({required this.phase});

  Color get _color {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            phase.toUpperCase(),
            style: AppTextStyles.sectionEyebrow.copyWith(color: _color),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends ConsumerWidget {
  final RunningOrderItem item;
  const _ScheduleTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      onDismissed: (_) =>
          ref.read(runningOrderProvider.notifier).deleteItem(item),
      child: GestureDetector(
        onTap: () => context.push('/dayof/running-order/edit/${item.id}',
            extra: item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealVibrant.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.time,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.tealVibrant,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
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
        if (members.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: 'No team members yet',
            subtitle: 'Add groomsmen, bridesmaids, and coordinators with their duties.',
          );
        }

        return RefreshIndicator(
          color: AppColors.tealVibrant,
          onRefresh: () => ref.read(teamProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: members.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _TeamTile(member: members[i]),
          ),
        );
      },
    );
  }
}

class _TeamTile extends ConsumerWidget {
  final TeamMember member;
  const _TeamTile({required this.member});

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
      onDismissed: (_) =>
          ref.read(teamProvider.notifier).deleteMember(member),
      child: GestureDetector(
        onTap: () => context.push('/dayof/team/brief/${member.id}', extra: member),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGrad,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
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
                    if (member.roleTitle.isNotEmpty)
                      Text(member.roleTitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${member.duties.length} duties',
                    style: AppTextStyles.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (member.pullsDietary)
                        const Icon(Icons.restaurant_outlined,
                            size: 14, color: AppColors.tealVibrant),
                      if (member.linkedVendorCategory.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.store_outlined,
                            size: 14, color: AppColors.tealVibrant),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => context.push(
                    '/dayof/team/edit/${member.id}',
                    extra: member),
                child: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.inkMute),
              ),
            ],
          ),
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
