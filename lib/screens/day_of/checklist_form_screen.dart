import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/checklist_item.dart';
import '../../providers/checklist_provider.dart';

class ChecklistFormScreen extends ConsumerStatefulWidget {
  final ChecklistItem? existing;

  const ChecklistFormScreen({super.key, this.existing});

  @override
  ConsumerState<ChecklistFormScreen> createState() =>
      _ChecklistFormScreenState();
}

class _ChecklistFormScreenState extends ConsumerState<ChecklistFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _item;
  late TextEditingController _person;
  late TextEditingController _notes;
  late String _destination;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _item = TextEditingController(text: e?.item ?? '');
    _person = TextEditingController(text: e?.personName ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _destination = e?.destination ?? AppConstants.checklistChurch;
  }

  @override
  void dispose() {
    _item.dispose();
    _person.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.existing != null) {
        await ref.read(checklistProvider.notifier).updateItem(
              widget.existing!.copyWith(
                item: _item.text.trim(),
                destination: _destination,
                personName: _person.text.trim(),
                notes: _notes.text.trim(),
              ),
            );
      } else {
        await ref.read(checklistProvider.notifier).addItem(
              item: _item.text.trim(),
              destination: _destination,
              personName: _person.text.trim(),
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
          isEditing ? 'Edit Item' : 'Add Item',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _item,
              decoration:
                  const InputDecoration(labelText: 'Item name *'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            Text('Destination', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            SegmentedButton<String>(
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
              selected: {_destination},
              onSelectionChanged: (s) =>
                  setState(() => _destination = s.first),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _person,
              decoration: const InputDecoration(
                  labelText: 'Person responsible (optional)'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
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
                  : Text(isEditing ? 'Save Changes' : 'Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}
