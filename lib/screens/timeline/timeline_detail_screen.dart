import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/task_item.dart';
import '../../widgets/timeline/task_tile.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_card.dart';
import '../../widgets/common/empty_state.dart';


// ─── Groups for the Tasks tab ─────────────────────────────────────────────────

enum _Group { overdue, today, tomorrow, thisWeek, later, noDate }

_Group _groupFor(TaskItem t) {
  if (t.dueDate == null) return _Group.noDate;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
  final diff = due.difference(today).inDays;
  if (diff < 0) return _Group.overdue;
  if (diff == 0) return _Group.today;
  if (diff == 1) return _Group.tomorrow;
  if (diff <= 7) return _Group.thisWeek;
  return _Group.later;
}

String _groupLabel(_Group g) {
  switch (g) {
    case _Group.overdue:   return 'Overdue';
    case _Group.today:     return 'Today';
    case _Group.tomorrow:  return 'Tomorrow';
    case _Group.thisWeek:  return 'This Week';
    case _Group.later:     return 'Later';
    case _Group.noDate:    return 'No Date';
  }
}

Color _groupColor(_Group g) {
  switch (g) {
    case _Group.overdue:  return AppColors.danger;
    case _Group.today:    return AppColors.tealVibrant;
    case _Group.tomorrow: return AppColors.steelBlue;
    default:              return AppColors.textSecondary;
  }
}

// ─── Main screen ─────────────────────────────────────────────────────────────

class TimelineDetailScreen extends ConsumerStatefulWidget {
  const TimelineDetailScreen({super.key});

  @override
  ConsumerState<TimelineDetailScreen> createState() =>
      _TimelineDetailScreenState();
}

class _TimelineDetailScreenState extends ConsumerState<TimelineDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _showDone = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksProvider);
    final stats = ref.watch(taskStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Timeline & Tasks', style: AppTextStyles.appBarTitle),
        actions: [
          if (_tab.index == 0)
            IconButton(
              icon: Icon(_showDone
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              tooltip: _showDone ? 'Hide done' : 'Show done',
              onPressed: () => setState(() => _showDone = !_showDone),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.read(tasksProvider.notifier).refresh(),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.checklist_outlined), text: 'Tasks'),
            Tab(icon: Icon(Icons.timeline_outlined), text: 'Timeline'),
            Tab(icon: Icon(Icons.view_week_outlined), text: 'Week'),
            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Month'),
          ],
          indicatorColor: AppColors.tealVibrant,
          labelColor: AppColors.tealVibrant,
          unselectedLabelColor: AppColors.textSecondary,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/timeline/add'),
        icon: const Icon(Icons.add_task),
        label: Text(_tab.index == 0 ? 'Add Task' : 'Add Event'),
      ),
      body: state.when(
        loading: () => const LoadingOverlay(message: 'Loading tasks…'),
        error: (e, _) => ErrorCard(
          message: e.toString(),
          onRetry: () => ref.read(tasksProvider.notifier).refresh(),
        ),
        data: (allTasks) => TabBarView(
          controller: _tab,
          children: [
            _TasksTab(
              allTasks: allTasks,
              stats: stats,
              showDone: _showDone,
              ref: ref,
              context: context,
              onDelete: _confirmDelete,
            ),
            _TimelineTab(
              allTasks: allTasks,
              ref: ref,
              context: context,
              onDelete: _confirmDelete,
            ),
            _WeekCalendarTab(
              allTasks: allTasks,
              ref: ref,
              outerContext: context,
              onDelete: _confirmDelete,
            ),
            _MonthCalendarTab(
              allTasks: allTasks,
              ref: ref,
              outerContext: context,
              onDelete: _confirmDelete,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, TaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${task.title}"?'),
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
      ref.read(tasksProvider.notifier).deleteTask(task);
    }
  }
}

// ─── Tasks Tab ────────────────────────────────────────────────────────────────

class _TasksTab extends StatelessWidget {
  final List<TaskItem> allTasks;
  final TaskStats stats;
  final bool showDone;
  final WidgetRef ref;
  final BuildContext context;
  final Future<void> Function(BuildContext, WidgetRef, TaskItem) onDelete;

  const _TasksTab({
    required this.allTasks,
    required this.stats,
    required this.showDone,
    required this.ref,
    required this.context,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext ctx) {
    if (allTasks.isEmpty) {
      return EmptyState(
        icon: Icons.checklist_outlined,
        title: 'No tasks yet',
        subtitle: 'Break your wedding planning into tasks and track your progress.',
        actionLabel: 'Add First Task',
        onAction: () => context.push('/timeline/add'),
      );
    }

    final visible = allTasks.where((t) => showDone || !t.isDone).toList();
    visible.sort((a, b) {
      final ga = _groupFor(a).index;
      final gb = _groupFor(b).index;
      if (ga != gb) return ga.compareTo(gb);
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    final grouped = <_Group, List<TaskItem>>{};
    for (final t in visible) {
      grouped.putIfAbsent(_groupFor(t), () => []).add(t);
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatPill(label: 'Total',     value: stats.total,              color: AppColors.textSecondary),
              _StatPill(label: 'Done',      value: stats.done,               color: AppColors.success),
              _StatPill(label: 'Overdue',   value: stats.overdue,            color: AppColors.danger),
              _StatPill(label: 'Remaining', value: stats.total - stats.done, color: AppColors.tealVibrant),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text('All done! Nothing left to show.',
                      style: AppTextStyles.cardSubtitle))
              : RefreshIndicator(
                  color: AppColors.tealVibrant,
                  onRefresh: () async => ref.read(tasksProvider.notifier).refresh(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      for (final group in _Group.values)
                        if (grouped.containsKey(group)) ...[
                          _GroupHeader(label: _groupLabel(group), color: _groupColor(group)),
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              children: grouped[group]!
                                  .map((task) => Column(children: [
                                        TaskTile(
                                          task: task,
                                          onToggle: () => ref.read(tasksProvider.notifier).toggleDone(task),
                                          onTap: () => context.push('/timeline/edit/${task.rowNumber}', extra: task),
                                          onDelete: () => onDelete(context, ref, task),
                                        ),
                                        if (task != grouped[group]!.last)
                                          const Divider(height: 1, indent: 56),
                                      ]))
                                  .toList(),
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Timeline Tab ─────────────────────────────────────────────────────────────
//
// Design: "Ceremony Program"
//  • One continuous spine down the centre (48 px wide column)
//  • Date appears centred above the first task on that date
//  • Bride cards sit to the LEFT of the spine
//  • Groom cards sit to the RIGHT of the spine
//  • Both/Us cards span the full width below the spine node
//  • Staggered fade+slide entrance — no scroll detection, always reliable
//  • Completed tasks collapse away with AnimatedSize + fade

const _kBrideAccent = Color(0xFFC07A92); // warm rose
const _kGroomAccent = AppColors.steelBlue;
const _kBothAccent  = AppColors.tealVibrant;
const _kSpineWidth  = 48.0;
const _kLineWidth   = 1.5;

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _TimelineTab extends StatelessWidget {
  final List<TaskItem> allTasks;
  final WidgetRef ref;
  final BuildContext context;
  final Future<void> Function(BuildContext, WidgetRef, TaskItem) onDelete;

  const _TimelineTab({
    required this.allTasks,
    required this.ref,
    required this.context,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext ctx) {
    final settings = ref.watch(settingsProvider).value;

    final dated = allTasks
        .where((t) => t.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    if (dated.isEmpty && settings == null) {
      return EmptyState(
        icon: Icons.timeline_outlined,
        title: 'No dated events yet',
        subtitle: "Add a date to your tasks and they'll appear here.",
        actionLabel: 'Add Task',
        onAction: () => context.push('/timeline/add'),
      );
    }

    final now    = DateTime.now();
    final today  = DateTime(now.year, now.month, now.day);
    final events = <_TLEvent>[];

    for (final t in dated) {
      events.add(_TLEvent.task(t));
    }
    if (settings != null) {
      events.add(_TLEvent.milestone(
        date: settings.weddingDate,
        label: settings.coupleNames.isNotEmpty
            ? '${settings.coupleNames} — Wedding Day'
            : 'Wedding Day',
      ));
    }
    events.sort((a, b) => a.date.compareTo(b.date));

    return RefreshIndicator(
      color: AppColors.tealVibrant,
      onRefresh: () async => ref.read(tasksProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 120),
        itemCount: events.length,
        itemBuilder: (ctx, i) {
          final e       = events[i];
          final isFirst = i == 0;
          final isLast  = i == events.length - 1;
          final showDate = isFirst || !_sameDay(events[i - 1].date, e.date);

          if (e.isMilestone) {
            return _TLMilestoneBanner(event: e, index: i, isLast: isLast);
          }

          final task     = e.task!;
          final isPast   = e.date.isBefore(today);
          final assignee = task.assignedTo;

          return _TLRow(
            key: ValueKey(task.rowNumber),
            event: e,
            task: task,
            isPast: isPast,
            isBride: assignee == 'Bride',
            isGroom: assignee == 'Groom',
            isFirst: isFirst,
            isLast: isLast,
            showDate: showDate,
            index: i,
            context: context,
            ref: ref,
            onDelete: onDelete,
          );
        },
      ),
    );
  }
}

// ── Per-item row ──────────────────────────────────────────────────────────────

class _TLRow extends StatefulWidget {
  final _TLEvent event;
  final TaskItem task;
  final bool isPast;
  final bool isBride;
  final bool isGroom;
  final bool isFirst;
  final bool isLast;
  final bool showDate;
  final int index;
  final BuildContext context;
  final WidgetRef ref;
  final Future<void> Function(BuildContext, WidgetRef, TaskItem) onDelete;

  const _TLRow({
    super.key,
    required this.event,
    required this.task,
    required this.isPast,
    required this.isBride,
    required this.isGroom,
    required this.isFirst,
    required this.isLast,
    required this.showDate,
    required this.index,
    required this.context,
    required this.ref,
    required this.onDelete,
  });

  @override
  State<_TLRow> createState() => _TLRowState();
}

class _TLRowState extends State<_TLRow> with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _doneCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _size;
  bool _prevDone = false;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _doneCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
        value: widget.task.isDone ? 0.0 : 1.0);

    // Slide direction matches card side
    final slideBegin = widget.isBride
        ? const Offset(-0.15, 0)
        : widget.isGroom
            ? const Offset(0.15, 0)
            : const Offset(0, 0.10);

    _fade  = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: slideBegin, end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _size  = CurvedAnimation(parent: _doneCtrl, curve: Curves.easeInOut);
    _prevDone = widget.task.isDone;

    // Fast staggered entrance — capped at 360 ms total
    final delay = Duration(milliseconds: (widget.index * 40).clamp(0, 360));
    Future.delayed(delay, () {
      if (mounted) _enterCtrl.forward();
    });
  }

  @override
  void didUpdateWidget(_TLRow old) {
    super.didUpdateWidget(old);
    if (!_prevDone && widget.task.isDone) {
      _prevDone = true;
      Future.delayed(const Duration(milliseconds: 240), () {
        if (mounted) _doneCtrl.reverse();
      });
    } else if (_prevDone && !widget.task.isDone) {
      _prevDone = false;
      _doneCtrl.forward();
    }
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _doneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task    = widget.task;
    final isBride = widget.isBride;
    final isGroom = widget.isGroom;
    final accent  = isBride ? _kBrideAccent : isGroom ? _kGroomAccent : _kBothAccent;
    final dotColor = task.isDone   ? AppColors.success
        : task.isOverdue           ? AppColors.danger
        : widget.isPast            ? AppColors.textSecondary
        : accent;

    return SizeTransition(
      sizeFactor: _size,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _size,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: _buildRow(task, accent, dotColor, isBride, isGroom),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
      TaskItem task, Color accent, Color dotColor, bool isBride, bool isGroom) {
    final spine = _SpineColumn(
      dotColor: dotColor,
      accent: accent,
      showDate: widget.showDate,
      date: widget.event.date,
      isPast: widget.isPast,
      isFirst: widget.isFirst,
      isLast: widget.isLast,
      isBothBelow: !isBride && !isGroom,
    );

    final card = _TLCard(
      task: task,
      isPast: widget.isPast,
      accent: accent,
      context: widget.context,
      ref: widget.ref,
      onDelete: widget.onDelete,
    );

    if (isBride || isGroom) {
      // Side layout — card left or right, spine centre
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: isBride
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8, right: 6, top: 6, bottom: 6),
                      child: Align(alignment: Alignment.centerRight, child: card))
                  : const SizedBox(),
            ),
            SizedBox(width: _kSpineWidth, child: Center(child: spine)),
            Expanded(
              child: isGroom
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6, right: 8, top: 6, bottom: 6),
                      child: Align(alignment: Alignment.centerLeft, child: card))
                  : const SizedBox(),
            ),
          ],
        ),
      );
    }

    // Both / Us — spine centred, card below spanning full width
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [SizedBox(width: _kSpineWidth, child: spine)],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: card,
        ),
        // bottom connector
        if (!widget.isLast)
          Center(
            child: Container(
              width: _kLineWidth,
              height: 12,
              color: AppColors.divider,
            ),
          ),
      ],
    );
  }
}

// ── Spine column ──────────────────────────────────────────────────────────────
// Draws: top-line → optional date → dot → bottom-line

class _SpineColumn extends StatelessWidget {
  final Color dotColor;
  final Color accent;
  final bool showDate;
  final DateTime date;
  final bool isPast;
  final bool isFirst;
  final bool isLast;
  final bool isBothBelow; // if true, skip bottom line (Column handles it)

  const _SpineColumn({
    required this.dotColor,
    required this.accent,
    required this.showDate,
    required this.date,
    required this.isPast,
    required this.isFirst,
    required this.isLast,
    required this.isBothBelow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top connector
        if (!isFirst)
          Container(width: _kLineWidth, height: 14, color: AppColors.divider),
        // Date display (only when date changes)
        if (showDate) ...[
          const SizedBox(height: 4),
          _DateDisplay(date: date, isPast: isPast, accent: accent),
          const SizedBox(height: 6),
        ] else
          const SizedBox(height: 8),
        // Node dot
        _SpineDot(color: dotColor),
        // Bottom connector (only for side layouts; Both handles its own)
        if (!isLast && !isBothBelow)
          Container(width: _kLineWidth, height: 14, color: AppColors.divider),
        if (!isLast && !isBothBelow)
          const SizedBox(height: 2),
      ],
    );
  }
}

// ── Spine dot ─────────────────────────────────────────────────────────────────

class _SpineDot extends StatelessWidget {
  final Color color;
  const _SpineDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(16),
        border: Border.all(color: color.withAlpha(65), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withAlpha(100), blurRadius: 6, spreadRadius: 1),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Date display ──────────────────────────────────────────────────────────────

class _DateDisplay extends StatelessWidget {
  final DateTime date;
  final bool isPast;
  final Color accent;
  const _DateDisplay({required this.date, required this.isPast, required this.accent});

  @override
  Widget build(BuildContext context) {
    final headColor = isPast ? AppColors.textSecondary : accent;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(
        DateFormat('MMM').format(date).toUpperCase(),
        style: TextStyle(
          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2.2,
          color: headColor.withAlpha(isPast ? 90 : 160),
        ),
      ),
      Text(
        DateFormat('d').format(date),
        style: TextStyle(
          fontSize: 30, fontWeight: FontWeight.w800, height: 0.9,
          color: isPast ? AppColors.textSecondary.withAlpha(70) : AppColors.deepTaupe,
        ),
      ),
      Text(
        DateFormat('EEE').format(date).toUpperCase(),
        style: TextStyle(
          fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1.4,
          color: AppColors.textSecondary.withAlpha(110),
        ),
      ),
    ]);
  }
}

// ── Task card ─────────────────────────────────────────────────────────────────

class _TLCard extends StatelessWidget {
  final TaskItem task;
  final bool isPast;
  final Color accent;
  final BuildContext context;
  final WidgetRef ref;
  final Future<void> Function(BuildContext, WidgetRef, TaskItem) onDelete;

  const _TLCard({
    required this.task,
    required this.isPast,
    required this.accent,
    required this.context,
    required this.ref,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext ctx) {
    final stripe = task.isDone   ? AppColors.success
        : task.isOverdue         ? AppColors.danger
        : accent;
    final tod = task.timeOfDay;

    return Opacity(
      opacity: (isPast && task.isDone) ? 0.38 : 1.0,
      child: GestureDetector(
        onTap: () => context.push('/timeline/edit/${task.rowNumber}', extra: task),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(color: stripe.withAlpha(30), blurRadius: 12, offset: const Offset(0, 3)),
              BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 3),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Left accent stripe
                Container(width: 3.5, color: stripe),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          // Checkbox
                          GestureDetector(
                            onTap: () => ref.read(tasksProvider.notifier).toggleDone(task),
                            child: Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: task.isDone ? AppColors.success
                                      : task.isOverdue ? AppColors.danger
                                      : accent.withAlpha(130),
                                  width: 1.8,
                                ),
                                color: task.isDone ? AppColors.success : Colors.transparent,
                              ),
                              child: task.isDone
                                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Title
                          Expanded(
                            child: Text(task.title,
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600, height: 1.3,
                                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                                  color: task.isDone ? AppColors.textSecondary : AppColors.textPrimary,
                                )),
                          ),
                          // Delete
                          GestureDetector(
                            onTap: () => onDelete(context, ref, task),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.close, size: 13,
                                  color: AppColors.warmGrey.withAlpha(120)),
                            ),
                          ),
                        ]),
                        if (tod != null || task.assignedTo.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(spacing: 5, runSpacing: 3, children: [
                            if (tod != null)
                              _TLPill(label: tod.format(ctx),
                                  icon: Icons.access_time_outlined, color: AppColors.tealVibrant),
                            if (task.assignedTo.isNotEmpty)
                              _TLPill(
                                label: task.assignedTo,
                                icon: task.assignedTo == 'Bride' ? Icons.woman_outlined
                                    : task.assignedTo == 'Groom' ? Icons.man_outlined
                                    : Icons.people_outline,
                                color: accent,
                              ),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pill ──────────────────────────────────────────────────────────────────────

class _TLPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _TLPill({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withAlpha(14),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withAlpha(38), width: 0.5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: color.withAlpha(185)),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );
}

// ── Milestone banner ──────────────────────────────────────────────────────────

class _TLMilestoneBanner extends StatefulWidget {
  final _TLEvent event;
  final int index;
  final bool isLast;
  const _TLMilestoneBanner(
      {required this.event, required this.index, required this.isLast});

  @override
  State<_TLMilestoneBanner> createState() => _TLMilestoneBannerState();
}

class _TLMilestoneBannerState extends State<_TLMilestoneBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: (widget.index * 40).clamp(0, 360)), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.tealOcean, AppColors.tealVibrant, AppColors.tealOcean],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.favorite, size: 10, color: Colors.white38),
            const SizedBox(width: 10),
            Text(
              (widget.event.label ?? '').toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800,
                  fontSize: 11, letterSpacing: 3.0),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.favorite, size: 10, color: Colors.white38),
          ]),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(widget.event.date),
            style: const TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 0.5),
          ),
        ]),
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _TLEvent {
  final DateTime date;
  final TaskItem? task;
  final bool isMilestone;
  final String? label;

  const _TLEvent._({
    required this.date,
    this.task,
    required this.isMilestone,
    this.label,
  });

  factory _TLEvent.task(TaskItem t) =>
      _TLEvent._(date: t.dueDate!, task: t, isMilestone: false);

  factory _TLEvent.milestone({
    required DateTime date,
    required String label,
  }) =>
      _TLEvent._(date: date, isMilestone: true, label: label);
}

// ─── Tasks tab helpers ────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _GroupHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 6),
      child: Row(children: [
        Container(
            width: 3, height: 16,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label.toUpperCase(),
            style: TextStyle(
                color: color, fontSize: 10,
                fontWeight: FontWeight.w800, letterSpacing: 1.8)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 0.5, color: color.withAlpha(35))),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('$value',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800, color: color, height: 1.1)),
      const SizedBox(height: 2),
      Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700,
              letterSpacing: 1.4, color: AppColors.textSecondary.withAlpha(180))),
    ]);
  }
}

// ─── Dot color helper ─────────────────────────────────────────────────────────

List<Color> _taskDots(List<TaskItem> tasks) => tasks.map((t) {
      if (t.isDone) return AppColors.success;
      if (t.isOverdue) return AppColors.danger;
      switch (t.priority) {
        case 'high':
          return AppColors.danger;
        case 'medium':
          return AppColors.warning;
        default:
          return AppColors.primary;
      }
    }).toList();

// ─── Nav arrow button ─────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceHi,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 18, color: AppColors.inkSoft),
        ),
      );
}

// ─── Shared calendar task card ────────────────────────────────────────────────

class _CalDayTask extends StatelessWidget {
  final TaskItem task;
  final WidgetRef ref;
  final BuildContext outerContext;
  final Future<void> Function(BuildContext, WidgetRef, TaskItem) onDelete;

  const _CalDayTask({
    required this.task,
    required this.ref,
    required this.outerContext,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accent = task.isDone
        ? AppColors.success
        : task.isOverdue
            ? AppColors.danger
            : task.priority == 'high'
                ? AppColors.danger
                : task.priority == 'medium'
                    ? AppColors.warning
                    : AppColors.primary;

    return GestureDetector(
      onTap: () =>
          outerContext.push('/timeline/edit/${task.rowNumber}', extra: task),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
                color: accent.withAlpha(22),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              ref.read(tasksProvider.notifier).toggleDone(task),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: accent.withAlpha(180), width: 1.8),
                              color: task.isDone ? accent : Colors.transparent,
                            ),
                            child: task.isDone
                                ? const Icon(Icons.check,
                                    size: 13, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontFamily: 'GoogleSans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: task.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.isDone
                                      ? AppColors.inkMute
                                      : AppColors.ink,
                                ),
                              ),
                              if (task.dueTime.isNotEmpty ||
                                  task.assignedTo.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Wrap(spacing: 6, children: [
                                  if (task.timeOfDay != null)
                                    _TLPill(
                                      label: task.timeOfDay!.format(context),
                                      icon: Icons.access_time_outlined,
                                      color: AppColors.primary,
                                    ),
                                  if (task.assignedTo.isNotEmpty)
                                    _TLPill(
                                      label: task.assignedTo,
                                      icon: task.assignedTo == 'Bride'
                                          ? Icons.woman_outlined
                                          : task.assignedTo == 'Groom'
                                              ? Icons.man_outlined
                                              : Icons.people_outline,
                                      color: accent,
                                    ),
                                ]),
                              ],
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => onDelete(outerContext, ref, task),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(Icons.close,
                                size: 14,
                                color: AppColors.inkMute.withAlpha(120)),
                          ),
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
    );
  }
}

// ─── Week Calendar Tab ────────────────────────────────────────────────────────

class _WeekCalendarTab extends StatefulWidget {
  final List<TaskItem> allTasks;
  final WidgetRef ref;
  final BuildContext outerContext;
  final Future<void> Function(BuildContext, WidgetRef, TaskItem) onDelete;

  const _WeekCalendarTab({
    required this.allTasks,
    required this.ref,
    required this.outerContext,
    required this.onDelete,
  });

  @override
  State<_WeekCalendarTab> createState() => _WeekCalendarTabState();
}

class _WeekCalendarTabState extends State<_WeekCalendarTab> {
  late DateTime _selected;
  int _weekOffset = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
  }

  DateTime get _weekStart {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return monday.add(Duration(days: _weekOffset * 7));
  }

  List<DateTime> get _days =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  List<TaskItem> _tasksOn(DateTime d) => widget.allTasks
      .where((t) =>
          t.dueDate != null &&
          t.dueDate!.year == d.year &&
          t.dueDate!.month == d.month &&
          t.dueDate!.day == d.day)
      .toList()
    ..sort((a, b) => a.dueTime.compareTo(b.dueTime));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = _days;
    final selectedTasks = _tasksOn(_selected);

    final first = days.first;
    final last = days.last;
    final header = first.month == last.month
        ? DateFormat('MMMM yyyy').format(first)
        : '${DateFormat('MMM').format(first)} – ${DateFormat('MMM yyyy').format(last)}';

    return Column(
      children: [
        // Week navigation
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              _NavArrow(
                  icon: Icons.chevron_left,
                  onTap: () => setState(() => _weekOffset--)),
              Expanded(
                child: Text(
                  header.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionEyebrow.copyWith(
                    fontSize: 11,
                    color: AppColors.ink,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              _NavArrow(
                  icon: Icons.chevron_right,
                  onTap: () => setState(() => _weekOffset++)),
            ],
          ),
        ),
        // Day strip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: days.map((day) {
              final isToday = day == today;
              final isSel = day == _selected;
              final dots = _taskDots(_tasksOn(day));
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selected = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      gradient: isSel ? AppColors.primaryGrad : null,
                      color: isToday && !isSel ? AppColors.primaryT : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('E').format(day)[0],
                          style: TextStyle(
                            fontFamily: 'GoogleSans',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isSel
                                ? Colors.white
                                : isToday
                                    ? AppColors.primary
                                    : AppColors.inkMute,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontFamily: 'CormorantGaramond',
                            fontStyle: FontStyle.italic,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1,
                            color: isSel
                                ? Colors.white
                                : isToday
                                    ? AppColors.primaryDeep
                                    : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dots
                                .take(3)
                                .map((c) => Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? Colors.white.withAlpha(200)
                                            : c,
                                        shape: BoxShape.circle,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        // Section label
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: Row(
            children: [
              Container(width: 18, height: 1, color: AppColors.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  DateFormat('EEEE, d MMMM').format(_selected).toUpperCase(),
                  style: AppTextStyles.sectionEyebrow,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selectedTasks.isNotEmpty)
                Text(
                  '${selectedTasks.length}',
                  style: AppTextStyles.sectionEyebrow
                      .copyWith(color: AppColors.primary),
                ),
            ],
          ),
        ),
        // Task list
        Expanded(
          child: selectedTasks.isEmpty
              ? Center(
                  child: Text('No tasks on this day',
                      style: AppTextStyles.cardSubtitle))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      widget.ref.read(tasksProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: selectedTasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _CalDayTask(
                      task: selectedTasks[i],
                      ref: widget.ref,
                      outerContext: widget.outerContext,
                      onDelete: widget.onDelete,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Month Calendar Tab ───────────────────────────────────────────────────────

class _MonthCalendarTab extends StatefulWidget {
  final List<TaskItem> allTasks;
  final WidgetRef ref;
  final BuildContext outerContext;
  final Future<void> Function(BuildContext, WidgetRef, TaskItem) onDelete;

  const _MonthCalendarTab({
    required this.allTasks,
    required this.ref,
    required this.outerContext,
    required this.onDelete,
  });

  @override
  State<_MonthCalendarTab> createState() => _MonthCalendarTabState();
}

class _MonthCalendarTabState extends State<_MonthCalendarTab> {
  late DateTime _selected;
  int _monthOffset = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
  }

  DateTime get _monthFirst {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset, 1);
  }

  List<TaskItem> _tasksOn(DateTime d) => widget.allTasks
      .where((t) =>
          t.dueDate != null &&
          t.dueDate!.year == d.year &&
          t.dueDate!.month == d.month &&
          t.dueDate!.day == d.day)
      .toList();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = _monthFirst;
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final leadingEmpty = first.weekday - 1; // Mon-based grid
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final selectedTasks = _tasksOn(_selected);

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _NavArrow(
                  icon: Icons.chevron_left,
                  onTap: () => setState(() => _monthOffset--)),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(first).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionEyebrow.copyWith(
                    fontSize: 11,
                    color: AppColors.ink,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              _NavArrow(
                  icon: Icons.chevron_right,
                  onTap: () => setState(() => _monthOffset++)),
            ],
          ),
        ),
        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                              fontFamily: 'GoogleSans',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkMute,
                              letterSpacing: 0.5,
                            )),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Day grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: List.generate(rows, (row) {
              return Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final dayNum = cellIndex - leadingEmpty + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 52));
                  }
                  final day = DateTime(first.year, first.month, dayNum);
                  final isToday = day == today;
                  final isSel = day == _selected;
                  final dots = _taskDots(_tasksOn(day));

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 52,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          gradient: isSel ? AppColors.primaryGrad : null,
                          color: isToday && !isSel ? AppColors.primaryT : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontFamily: 'CormorantGaramond',
                                fontStyle: FontStyle.italic,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1,
                                color: isSel
                                    ? Colors.white
                                    : isToday
                                        ? AppColors.primaryDeep
                                        : AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 5,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: dots
                                    .take(3)
                                    .map((c) => Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 1),
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? Colors.white.withAlpha(200)
                                                : c,
                                            shape: BoxShape.circle,
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        // Section label
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: Row(
            children: [
              Container(width: 18, height: 1, color: AppColors.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  DateFormat('EEEE, d MMMM').format(_selected).toUpperCase(),
                  style: AppTextStyles.sectionEyebrow,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selectedTasks.isNotEmpty)
                Text(
                  '${selectedTasks.length}',
                  style: AppTextStyles.sectionEyebrow
                      .copyWith(color: AppColors.primary),
                ),
            ],
          ),
        ),
        // Task list for selected day
        Expanded(
          child: selectedTasks.isEmpty
              ? Center(
                  child: Text('No tasks on this day',
                      style: AppTextStyles.cardSubtitle))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      widget.ref.read(tasksProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: selectedTasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _CalDayTask(
                      task: selectedTasks[i],
                      ref: widget.ref,
                      outerContext: widget.outerContext,
                      onDelete: widget.onDelete,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
