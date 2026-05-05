import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/task_item.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/common/chip_picker.dart';

final _dateFormat = DateFormat('d MMM y');

const _taskCategoryIcons = <String, IconData>{
  'Venue':           Icons.location_city_outlined,
  'Catering':        Icons.restaurant_outlined,
  'Photography':     Icons.camera_alt_outlined,
  'Flowers & Décor': Icons.local_florist_outlined,
  'Attire':          Icons.checkroom_outlined,
  'Guests':          Icons.people_outline,
  'Admin & Legal':   Icons.description_outlined,
  'Day Of':          Icons.today_outlined,
  'Other':           Icons.more_horiz,
};

const _assigneeIcons = <String, IconData>{
  'Bride': Icons.woman_outlined,
  'Groom': Icons.man_outlined,
  'Both':  Icons.people_outline,
};

class TaskFormScreen extends ConsumerStatefulWidget {
  final TaskItem? existing;

  const TaskFormScreen({super.key, this.existing});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _notes;
  late String _category;
  late String _priority;
  late String _assignedTo;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _category = e?.category ?? AppConstants.taskCategories.first;
    _priority = e?.priority ?? AppConstants.priorityMedium;
    _assignedTo = e?.assignedTo ?? '';
    _dueDate = e?.dueDate;
    _dueTime = e?.timeOfDay;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.tealVibrant),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.tealVibrant),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _displayTime(TimeOfDay t) => t.format(context);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final timeStr = _dueTime != null ? _formatTime(_dueTime!) : '';
      if (widget.existing != null) {
        await ref.read(tasksProvider.notifier).updateTask(
              widget.existing!.copyWith(
                title: _title.text.trim(),
                category: _category,
                dueDate: _dueDate,
                priority: _priority,
                notes: _notes.text.trim(),
                dueTime: timeStr,
                assignedTo: _assignedTo,
                clearDueDate: _dueDate == null,
                clearDueTime: _dueTime == null,
              ),
            );
      } else {
        await ref.read(tasksProvider.notifier).addTask(
              title: _title.text.trim(),
              category: _category,
              dueDate: _dueDate,
              priority: _priority,
              notes: _notes.text.trim(),
              dueTime: timeStr,
              assignedTo: _assignedTo,
            );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.danger),
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
          isEditing ? 'Edit Task' : 'Add Task',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Task title *'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            ChipPicker(
              label: 'Category',
              options: AppConstants.taskCategories,
              selected: _category,
              icons: _taskCategoryIcons,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 20),

            // Assigned to
            Text('Assigned to', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ...AppConstants.taskAssignees.map((a) {
                  final isSelected = _assignedTo == a;
                  return ChoiceChip(
                    label: Text(a),
                    avatar: Icon(
                      _assigneeIcons[a],
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.tealVibrant,
                    ),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _assignedTo = isSelected ? '' : a),
                    selectedColor: AppColors.tealVibrant,
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.tealVibrant : AppColors.divider,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    showCheckmark: false,
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),

            // Priority
            Text('Priority', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'low',
                  label: Text('Low'),
                  icon: Icon(Icons.arrow_downward_rounded, size: 16),
                ),
                ButtonSegment(
                  value: 'medium',
                  label: Text('Medium'),
                  icon: Icon(Icons.remove_rounded, size: 16),
                ),
                ButtonSegment(
                  value: 'high',
                  label: Text('High'),
                  icon: Icon(Icons.arrow_upward_rounded, size: 16),
                ),
              ],
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
              style: ButtonStyle(
                iconColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return Colors.white;
                  return AppColors.textSecondary;
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Date & time row
            Text('Due date & time', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            Row(
              children: [
                // Date picker
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
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
                          Icon(Icons.event_outlined,
                              size: 18,
                              color: _dueDate != null
                                  ? AppColors.tealVibrant
                                  : AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _dueDate != null
                                  ? _dateFormat.format(_dueDate!)
                                  : 'Date',
                              style: _dueDate != null
                                  ? AppTextStyles.bodyMedium
                                  : AppTextStyles.bodySmall,
                            ),
                          ),
                          if (_dueDate != null)
                            GestureDetector(
                              onTap: () =>
                                  setState(() { _dueDate = null; _dueTime = null; }),
                              child: const Icon(Icons.clear,
                                  size: 16, color: AppColors.warmGrey),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Time picker
                Expanded(
                  child: GestureDetector(
                    onTap: _dueDate != null ? _pickTime : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: _dueDate != null
                            ? AppColors.surface
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_outlined,
                              size: 18,
                              color: _dueTime != null
                                  ? AppColors.tealVibrant
                                  : AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _dueTime != null
                                  ? _displayTime(_dueTime!)
                                  : 'Time',
                              style: _dueTime != null
                                  ? AppTextStyles.bodyMedium
                                  : AppTextStyles.bodySmall,
                            ),
                          ),
                          if (_dueTime != null)
                            GestureDetector(
                              onTap: () => setState(() => _dueTime = null),
                              child: const Icon(Icons.clear,
                                  size: 16, color: AppColors.warmGrey),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Calendar sync notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tealVibrant.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.tealVibrant.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 18, color: AppColors.tealVibrant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Google Calendar sync coming soon — tasks with dates will automatically appear in your calendar.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.tealVibrant),
                    ),
                  ),
                ],
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
                  : Text(isEditing ? 'Save Changes' : 'Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}
