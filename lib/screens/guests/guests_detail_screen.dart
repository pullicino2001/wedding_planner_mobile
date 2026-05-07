import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/guests_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sheets_service_provider.dart';
import '../../services/sheets/sheets_service.dart';
import '../../models/guest.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_card.dart';

class GuestsDetailScreen extends ConsumerStatefulWidget {
  const GuestsDetailScreen({super.key});

  @override
  ConsumerState<GuestsDetailScreen> createState() => _GuestsDetailScreenState();
}

class _GuestsDetailScreenState extends ConsumerState<GuestsDetailScreen> {
  String _search = '';
  String? _filterRsvp;
  String? _filterRelation;
  bool _settingUp = false;

  List<Guest> _filtered(List<Guest> guests) {
    return guests.where((g) {
      final matchSearch = _search.isEmpty ||
          g.fullName.toLowerCase().contains(_search.toLowerCase()) ||
          g.email.toLowerCase().contains(_search.toLowerCase());
      final matchRsvp = _filterRsvp == null || g.rsvpStatus == _filterRsvp;
      final matchRelation =
          _filterRelation == null || g.relation == _filterRelation;
      return matchSearch && matchRsvp && matchRelation;
    }).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  // ── Sheet ID extraction ────────────────────────────────────────────────
  String? _extractSheetId(String input) {
    final trimmed = input.trim();
    final match =
        RegExp(r'/spreadsheets/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
    if (match != null) return match.group(1);
    if (RegExp(r'^[a-zA-Z0-9_-]{20,}$').hasMatch(trimmed)) return trimmed;
    return null;
  }

  // ── Create a new guest sheet ───────────────────────────────────────────
  Future<void> _createSheet() async {
    setState(() => _settingUp = true);
    try {
      final client = await ref.read(authClientProvider.future);
      if (client == null) throw Exception('Not signed in');
      final coupleNames =
          ref.read(settingsProvider).value?.coupleNames ?? 'Wedding';
      final result =
          await SheetsService.createGuestSheet(client, coupleNames);
      await ref
          .read(settingsProvider.notifier)
          .saveGuestSheet(id: result.id, url: result.url);
      if (mounted) ref.read(guestsProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create sheet: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _settingUp = false);
    }
  }

  // ── Link an existing sheet ─────────────────────────────────────────────
  Future<void> _linkSheet() async {
    final urlCtrl = TextEditingController();
    String? errorText;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Link your guest sheet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste your Google Sheets URL or spreadsheet ID.\n\n'
                'The app reads each row as groups of guests. '
                'Columns A–B are person 1 (Name / Surname), '
                'C–D are person 2, E–F are person 3. '
                'Colour the cell green for confirmed, red for declined.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'https://docs.google.com/spreadsheets/d/…',
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final id = _extractSheetId(urlCtrl.text);
                if (id == null) {
                  setDialogState(() =>
                      errorText = 'Could not find a valid spreadsheet ID.');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text('Link',
                  style: TextStyle(color: AppColors.tealVibrant)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) {
      urlCtrl.dispose();
      return;
    }

    final newId = _extractSheetId(urlCtrl.text)!;
    final input = urlCtrl.text.trim();
    urlCtrl.dispose();
    final newUrl = input.contains('spreadsheets/d/')
        ? input.split('?').first
        : 'https://docs.google.com/spreadsheets/d/$newId';

    await ref.read(settingsProvider.notifier).saveGuestSheet(
          id: newId,
          url: newUrl,
        );
    if (mounted) {
      ref.read(guestsProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guest sheet linked — loading your list…'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsValue = ref.watch(settingsProvider).value;
    final hasGuestSheet = settingsValue?.hasGuestSheet ?? false;
    final state = ref.watch(guestsProvider);
    final stats = ref.watch(guestStatsProvider);
    final customRelations = ref.watch(customRelationsProvider);
    final allRelations = [...AppConstants.guestRelations, ...customRelations];

    // ── No guest sheet yet — show setup UI ──────────────────────────────
    if (!hasGuestSheet) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Guests', style: AppTextStyles.appBarTitle),
        ),
        body: _settingUp
            ? const LoadingOverlay(message: 'Creating your guest sheet…')
            : _GuestSheetSetup(
                onCreate: _createSheet,
                onLink: _linkSheet,
              ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Guests', style: AppTextStyles.appBarTitle),
        actions: [
          GestureDetector(
            onTap: () => ref.read(guestsProvider.notifier).refresh(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.surfaceHi,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh_outlined,
                  size: 20, color: AppColors.inkSoft),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: state.when(
        loading: () => const LoadingOverlay(message: 'Loading guests…'),
        error: (e, _) => ErrorCard(
          message: e.toString(),
          onRetry: () => ref.read(guestsProvider.notifier).refresh(),
        ),
        data: (allGuests) {
          if (allGuests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 48, color: AppColors.inkMute),
                    const SizedBox(height: 16),
                    Text('No guests found',
                        style: AppTextStyles.cardTitle),
                    const SizedBox(height: 8),
                    Text(
                      'Make sure your sheet has at least one row of names below the header.',
                      style: AppTextStyles.cardSubtitle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final filtered = _filtered(allGuests);

          return Column(
            children: [
              // Sync banner — always shown (guest sheet is always read-only)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryT.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sync_outlined,
                          size: 14, color: AppColors.primaryDeep),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Synced from your Google Sheet · read-only · refreshes every 30 s',
                          style: AppTextStyles.sectionEyebrow.copyWith(
                            fontSize: 9,
                            color: AppColors.primaryDeep,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // RSVP donut hero card
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHi,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      _RsvpDonut(
                        confirmed: stats.confirmed,
                        pending: stats.pending,
                        declined: stats.declined,
                        total: stats.total,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: [
                            _LegendRow(
                              dot: AppColors.success,
                              label: 'Confirmed',
                              value: stats.confirmed,
                            ),
                            const SizedBox(height: 8),
                            _LegendRow(
                              dot: AppColors.inkMute,
                              label: 'Pending',
                              value: stats.pending,
                            ),
                            const SizedBox(height: 8),
                            _LegendRow(
                              dot: AppColors.danger,
                              label: 'Declined',
                              value: stats.declined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // RSVP filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      count: stats.total,
                      selected: _filterRsvp == null,
                      onTap: () => setState(() => _filterRsvp = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Confirmed',
                      count: stats.confirmed,
                      color: AppColors.success,
                      dot: true,
                      selected: _filterRsvp == AppConstants.rsvpConfirmed,
                      onTap: () => setState(() => _filterRsvp =
                          _filterRsvp == AppConstants.rsvpConfirmed
                              ? null
                              : AppConstants.rsvpConfirmed),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pending',
                      count: stats.pending,
                      color: AppColors.inkMute,
                      dot: true,
                      selected: _filterRsvp == AppConstants.rsvpPending,
                      onTap: () => setState(() => _filterRsvp =
                          _filterRsvp == AppConstants.rsvpPending
                              ? null
                              : AppConstants.rsvpPending),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Declined',
                      count: stats.declined,
                      color: AppColors.danger,
                      dot: true,
                      selected: _filterRsvp == AppConstants.rsvpDeclined,
                      onTap: () => setState(() => _filterRsvp =
                          _filterRsvp == AppConstants.rsvpDeclined
                              ? null
                              : AppConstants.rsvpDeclined),
                    ),
                  ],
                ),
              ),

              // Relation filter — only shown when there are categories to filter by
              if (allRelations.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filterRelation == null,
                        onTap: () => setState(() => _filterRelation = null),
                      ),
                      ...allRelations.map((rel) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _FilterChip(
                              label: rel,
                              color: AppColors.primary,
                              selected: _filterRelation == rel,
                              onTap: () => setState(() => _filterRelation =
                                  _filterRelation == rel ? null : rel),
                            ),
                          )),
                    ],
                  ),
                ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search guests…',
                    prefixIcon: const Icon(Icons.search, size: 18,
                        color: AppColors.inkMute),
                    suffixIcon: const Icon(Icons.tune_outlined, size: 16,
                        color: AppColors.inkMute),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),

              // Section header
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
                child: Row(
                  children: [
                    Container(width: 18, height: 1, color: AppColors.ink),
                    const SizedBox(width: 10),
                    Text(
                      'THE LIST · ${stats.total} SOULS',
                      style: AppTextStyles.sectionEyebrow,
                    ),
                  ],
                ),
              ),

              // Guest list — expandable name cells
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('No guests match your search.',
                            style: AppTextStyles.cardSubtitle),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async =>
                            ref.read(guestsProvider.notifier).refresh(),
                        child: Builder(builder: (_) {
                          final groups = _buildGroups(filtered);
                          return ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(18, 0, 18, 100),
                            itemCount: groups.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => _GuestCell(
                              guests: groups[i],
                            ),
                          );
                        }),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Groups guests by row number so household members share one card.
  List<List<Guest>> _buildGroups(List<Guest> guests) {
    final map = <int, List<Guest>>{};
    for (final g in guests) {
      map.putIfAbsent(g.rowNumber, () => []).add(g);
    }
    return map.values.toList();
  }
}

// ── RSVP Donut ────────────────────────────────────────────────────────────────

class _RsvpDonut extends StatelessWidget {
  final int confirmed;
  final int pending;
  final int declined;
  final int total;

  const _RsvpDonut({
    required this.confirmed,
    required this.pending,
    required this.declined,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final rsvpPct =
        total > 0 ? (confirmed / total * 100).toStringAsFixed(0) : '0';
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(100, 100),
            painter: _DonutPainter(
              confirmed: confirmed,
              pending: pending,
              declined: declined,
              total: total,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$rsvpPct%',
                style: const TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  fontSize: 26,
                  color: AppColors.ink,
                  height: 1,
                ),
              ),
              Text(
                "RSVP'D",
                style: AppTextStyles.sectionEyebrow.copyWith(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int confirmed;
  final int pending;
  final int declined;
  final int total;

  const _DonutPainter({
    required this.confirmed,
    required this.pending,
    required this.declined,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    const strokeWidth = 10.0;
    const gapAngle = 0.04;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.surface;
    canvas.drawCircle(center, radius, trackPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -math.pi / 2;

    void drawSegment(int count, Color color) {
      if (count <= 0) return;
      final sweep = 2 * math.pi * count / total;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(rect, startAngle, sweep - gapAngle, false, paint);
      startAngle += sweep;
    }

    drawSegment(confirmed, AppColors.success);
    drawSegment(pending, AppColors.inkMute);
    drawSegment(declined, AppColors.danger);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.confirmed != confirmed ||
      old.pending != pending ||
      old.declined != declined ||
      old.total != total;
}

// ── Legend row ────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  final Color dot;
  final String label;
  final int value;
  const _LegendRow(
      {required this.dot, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
        const Spacer(),
        Text(
          '$value',
          style: const TextStyle(
            fontFamily: 'CormorantGaramond',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

// ── Expandable guest cell ─────────────────────────────────────────────────────

class _GuestCell extends StatefulWidget {
  final List<Guest> guests;

  const _GuestCell({
    required this.guests,
  });

  @override
  State<_GuestCell> createState() => _GuestCellState();
}

class _GuestCellState extends State<_GuestCell> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final guests = widget.guests;
    final isGroup = guests.length > 1;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                _expanded ? AppColors.primary.withAlpha(70) : AppColors.line,
          ),
          boxShadow: _expanded
              ? [
                  BoxShadow(
                      color: AppColors.primary.withAlpha(14),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    18, isGroup ? 14 : 16, 14, isGroup ? 14 : 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < guests.length; i++) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _RsvpDot(status: guests[i].rsvpStatus),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    guests[i].fullName,
                                    style: TextStyle(
                                      fontFamily: 'CormorantGaramond',
                                      fontStyle: FontStyle.italic,
                                      fontSize: isGroup ? 18 : 22,
                                      fontWeight: FontWeight.w600,
                                      height: 1.15,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (i < guests.length - 1)
                              const SizedBox(height: 4),
                          ],
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color:
                            _expanded ? AppColors.primary : AppColors.inkMute,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: _expanded
                    ? _CellDetail(guests: guests)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cell expanded detail ──────────────────────────────────────────────────────

class _CellDetail extends StatelessWidget {
  final List<Guest> guests;

  const _CellDetail({required this.guests});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < guests.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                ],
                _GuestDetails(
                  guest: guests[i],
                  showName: guests.length > 1,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Per-guest detail block ────────────────────────────────────────────────────

class _GuestDetails extends StatelessWidget {
  final Guest guest;
  final bool showName;

  const _GuestDetails({required this.guest, required this.showName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showName)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              guest.fullName,
              style: AppTextStyles.sectionEyebrow
                  .copyWith(color: AppColors.inkSoft),
            ),
          ),
        Row(
          children: [
            _RsvpPill(status: guest.rsvpStatus),
            if (guest.relation.isNotEmpty) ...[
              const SizedBox(width: 6),
              _InfoPill(label: guest.relation),
            ],
            if (guest.hasPlusOne) ...[
              const SizedBox(width: 6),
              _InfoPill(label: '+1', icon: Icons.person_add_outlined),
            ],
          ],
        ),
        if (guest.email.isNotEmpty) ...[
          const SizedBox(height: 10),
          _DetailRow(icon: Icons.mail_outline_rounded, text: guest.email),
        ],
        if (guest.phone.isNotEmpty) ...[
          const SizedBox(height: 6),
          _DetailRow(icon: Icons.phone_outlined, text: guest.phone),
        ],
        if (guest.mealChoice.isNotEmpty || guest.dietary.isNotEmpty) ...[
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.restaurant_outlined,
            text: [guest.mealChoice, guest.dietary]
                .where((s) => s.isNotEmpty)
                .join(' · '),
          ),
        ],
      ],
    );
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _RsvpDot extends StatelessWidget {
  final String status;
  const _RsvpDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed' => AppColors.success,
      'declined'  => AppColors.danger,
      _           => AppColors.inkMute.withAlpha(80),
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RsvpPill extends StatelessWidget {
  final String status;
  const _RsvpPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'confirmed' => ('Confirmed', AppColors.success),
      'declined'  => ('Declined', AppColors.danger),
      _           => ('Pending', AppColors.inkMute),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontFamily: 'GoogleSans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color)),
      ]),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _InfoPill({required this.label, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceHi,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: AppColors.inkMute),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: const TextStyle(
                  fontFamily: 'GoogleSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMute)),
        ]),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: AppColors.inkMute),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.inkSoft))),
        ],
      );
}

// ── Guest sheet setup card ────────────────────────────────────────────────────

class _GuestSheetSetup extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onLink;

  const _GuestSheetSetup({required this.onCreate, required this.onLink});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 52, color: AppColors.inkMute),
            const SizedBox(height: 20),
            Text(
              'Set up your guest list',
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 26,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your guest list lives in its own Google Sheet. Create a fresh one or link a sheet you already have.',
              style: AppTextStyles.cardSubtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _SetupOption(
              icon: Icons.add_chart_outlined,
              title: 'Create a guest sheet',
              subtitle: "We'll make a fresh sheet ready for you to fill in.",
              onTap: onCreate,
            ),
            const SizedBox(height: 12),
            _SetupOption(
              icon: Icons.link_outlined,
              title: 'Link your own sheet',
              subtitle: 'Paste a link to a Google Sheet you already use.',
              onTap: onLink,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SetupOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryT.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: AppColors.primaryDeep),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.cardSubtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.inkMute),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final bool dot;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.color,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? c.withAlpha(36)
              : AppColors.surfaceHi,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? c : AppColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? c : AppColors.inkSoft,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: AppTextStyles.labelSmall.copyWith(
                  color: selected ? c : AppColors.inkMute,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
