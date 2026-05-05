import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/team_member.dart';
import '../../providers/team_provider.dart';
import '../../providers/vendors_provider.dart';

class TeamMemberFormScreen extends ConsumerStatefulWidget {
  final TeamMember? existing;

  const TeamMemberFormScreen({super.key, this.existing});

  @override
  ConsumerState<TeamMemberFormScreen> createState() =>
      _TeamMemberFormScreenState();
}

class _TeamMemberFormScreenState
    extends ConsumerState<TeamMemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _roleTitle;
  late List<TeamDuty> _duties;
  late String _linkedVendorCategory;
  late bool _pullsDietary;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _roleTitle = TextEditingController(text: e?.roleTitle ?? '');
    _duties = List.from(e?.duties ?? []);
    _linkedVendorCategory = e?.linkedVendorCategory ?? '';
    _pullsDietary = e?.pullsDietary ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _roleTitle.dispose();
    super.dispose();
  }

  void _addDuty(String phase) {
    setState(() {
      _duties.add(TeamDuty(phase: phase, description: ''));
    });
  }

  void _updateDuty(int index, String description) {
    setState(() {
      _duties[index] =
          TeamDuty(phase: _duties[index].phase, description: description);
    });
  }

  void _removeDuty(int index) {
    setState(() => _duties.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // Remove empty duty lines
    final cleanDuties =
        _duties.where((d) => d.description.trim().isNotEmpty).toList();
    setState(() => _saving = true);
    try {
      if (widget.existing != null) {
        await ref.read(teamProvider.notifier).updateMember(
              widget.existing!.copyWith(
                name: _name.text.trim(),
                phone: _phone.text.trim(),
                roleTitle: _roleTitle.text.trim(),
                duties: cleanDuties,
                linkedVendorCategory: _linkedVendorCategory,
                pullsDietary: _pullsDietary,
              ),
            );
      } else {
        await ref.read(teamProvider.notifier).addMember(
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              roleTitle: _roleTitle.text.trim(),
              duties: cleanDuties,
              linkedVendorCategory: _linkedVendorCategory,
              pullsDietary: _pullsDietary,
            );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.danger),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final vendorsState = ref.watch(vendorsProvider);
    final vendorCategories = [
      '',
      ...AppConstants.vendorCategories,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Person' : 'Add Person',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration:
                  const InputDecoration(labelText: 'Full name *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              decoration:
                  const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roleTitle,
              decoration: const InputDecoration(
                  labelText: 'Role title (e.g. Groomsman, Coordinator)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            // Duties section
            Text('Duties', style: AppTextStyles.labelLarge),
            const SizedBox(height: 4),
            Text(
              'Add duties per phase. Empty lines will be removed on save.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),

            for (final phase in AppConstants.dutyPhases) ...[
              _DutyPhaseSection(
                phase: phase,
                duties: _duties,
                onAdd: () => _addDuty(phase),
                onUpdate: _updateDuty,
                onRemove: _removeDuty,
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Smart data linking
            Text('Smart Data', style: AppTextStyles.labelLarge),
            const SizedBox(height: 4),
            Text(
              'Link relevant data that will appear in this person\'s brief.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),

            // Dietary toggle
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_outlined,
                      size: 20, color: AppColors.tealVibrant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pull dietary requirements',
                            style: AppTextStyles.labelLarge),
                        Text(
                          'Shows guest dietary breakdown in their brief.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _pullsDietary,
                    onChanged: (v) => setState(() => _pullsDietary = v),
                    activeColor: AppColors.tealVibrant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Vendor category link
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store_outlined,
                      size: 20, color: AppColors.tealVibrant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _linkedVendorCategory.isEmpty
                            ? ''
                            : _linkedVendorCategory,
                        isExpanded: true,
                        hint: Text('Link a vendor category (optional)',
                            style: AppTextStyles.bodySmall),
                        items: vendorCategories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat.isEmpty ? 'No vendor link' : cat,
                              style: AppTextStyles.bodyMedium,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(
                            () => _linkedVendorCategory = v ?? ''),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_linkedVendorCategory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: vendorsState.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (vendors) {
                    final matches = vendors
                        .where((v) => v.category == _linkedVendorCategory)
                        .toList();
                    if (matches.isEmpty) {
                      return Text(
                        'No vendors found for "$_linkedVendorCategory"',
                        style: AppTextStyles.bodySmall,
                      );
                    }
                    return Text(
                      '${matches.length} vendor${matches.length > 1 ? 's' : ''} found: ${matches.map((v) => v.name).join(', ')}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.tealVibrant),
                    );
                  },
                ),
              ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEditing ? 'Save Changes' : 'Add Person'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DutyPhaseSection extends StatefulWidget {
  final String phase;
  final List<TeamDuty> duties;
  final VoidCallback onAdd;
  final void Function(int index, String description) onUpdate;
  final void Function(int index) onRemove;

  const _DutyPhaseSection({
    required this.phase,
    required this.duties,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_DutyPhaseSection> createState() => _DutyPhaseSectionState();
}

class _DutyPhaseSectionState extends State<_DutyPhaseSection> {
  @override
  Widget build(BuildContext context) {
    final phaseDuties = widget.duties
        .asMap()
        .entries
        .where((e) => e.value.phase == widget.phase)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.phase,
              style: AppTextStyles.sectionEyebrow
                  .copyWith(color: AppColors.tealVibrant),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.tealVibrant,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: AppTextStyles.labelSmall,
              ),
            ),
          ],
        ),
        if (phaseDuties.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('No ${widget.phase.toLowerCase()} duties.',
                style: AppTextStyles.bodySmall),
          ),
        for (final entry in phaseDuties)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.drag_indicator,
                    size: 16, color: AppColors.inkMute),
                const SizedBox(width: 4),
                Expanded(
                  child: TextFormField(
                    initialValue: entry.value.description,
                    decoration: InputDecoration(
                      hintText: '${widget.phase} duty…',
                      hintStyle: AppTextStyles.bodySmall,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (v) => widget.onUpdate(entry.key, v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 16, color: AppColors.inkMute),
                  onPressed: () => widget.onRemove(entry.key),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
