import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/running_order_item.dart';
import '../../providers/running_order_provider.dart';

class RunningOrderFormScreen extends ConsumerStatefulWidget {
  final RunningOrderItem? existing;

  const RunningOrderFormScreen({super.key, this.existing});

  @override
  ConsumerState<RunningOrderFormScreen> createState() =>
      _RunningOrderFormScreenState();
}

class _RunningOrderFormScreenState
    extends ConsumerState<RunningOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _description;
  late TextEditingController _notes;
  late String _phase;
  TimeOfDay? _time;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _description = TextEditingController(text: e?.description ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _phase = e?.phase ?? AppConstants.runningOrderPhases.first;
    if (e != null && e.time.isNotEmpty) {
      final parts = e.time.split(':');
      if (parts.length == 2) {
        _time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.tealVibrant),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final timeStr = _time != null ? _formatTime(_time!) : '';
      if (widget.existing != null) {
        await ref.read(runningOrderProvider.notifier).updateItem(
              widget.existing!.copyWith(
                time: timeStr,
                phase: _phase,
                description: _description.text.trim(),
                notes: _notes.text.trim(),
              ),
            );
      } else {
        await ref.read(runningOrderProvider.notifier).addItem(
              time: timeStr,
              phase: _phase,
              description: _description.text.trim(),
              notes: _notes.text.trim(),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Event' : 'Add Event',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _description,
              decoration:
                  const InputDecoration(labelText: 'Event description *'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            Text('Phase', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: AppConstants.runningOrderPhases.map((p) {
                final isSelected = _phase == p;
                return ChoiceChip(
                  label: Text(p),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _phase = p),
                  selectedColor: AppColors.tealVibrant,
                  backgroundColor: AppColors.surfaceVariant,
                  labelStyle: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.tealVibrant
                        : AppColors.divider,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Text('Time', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_outlined,
                        size: 18,
                        color: _time != null
                            ? AppColors.tealVibrant
                            : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _time != null
                            ? _formatTime(_time!)
                            : 'Select time',
                        style: _time != null
                            ? AppTextStyles.bodyMedium
                            : AppTextStyles.bodySmall,
                      ),
                    ),
                    if (_time != null)
                      GestureDetector(
                        onTap: () => setState(() => _time = null),
                        child: const Icon(Icons.clear,
                            size: 16, color: AppColors.warmGrey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
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
                  : Text(isEditing ? 'Save Changes' : 'Add Event'),
            ),
          ],
        ),
      ),
    );
  }
}
