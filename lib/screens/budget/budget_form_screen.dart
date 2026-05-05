import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/budget_item.dart';
import '../../providers/budget_provider.dart';
import '../../widgets/common/chip_picker.dart';

const _budgetCategoryIcons = <String, IconData>{
  'Venue':                Icons.location_city_outlined,
  'Catering':             Icons.restaurant_outlined,
  'Photography':          Icons.camera_alt_outlined,
  'Videography':          Icons.videocam_outlined,
  'Flowers & Décor':      Icons.local_florist_outlined,
  'Music & Entertainment':Icons.music_note_outlined,
  'Cake':                 Icons.cake_outlined,
  'Attire & Beauty':      Icons.checkroom_outlined,
  'Stationery':           Icons.mail_outline,
  'Transport':            Icons.directions_car_outlined,
  'Accommodation':        Icons.hotel_outlined,
  'Honeymoon':            Icons.flight_outlined,
  'Gifts & Favours':      Icons.card_giftcard_outlined,
  'Other':                Icons.more_horiz,
};

class BudgetFormScreen extends ConsumerStatefulWidget {
  final BudgetItem? existing;

  const BudgetFormScreen({super.key, this.existing});

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _category;
  late TextEditingController _item;
  late TextEditingController _estimated;
  late TextEditingController _actual;
  late bool _paid;
  late TextEditingController _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _category = e?.category ?? AppConstants.budgetCategories.first;
    _item = TextEditingController(text: e?.item ?? '');
    _estimated = TextEditingController(
        text: e != null && e.estimated > 0 ? e.estimated.toStringAsFixed(0) : '');
    _actual = TextEditingController(
        text: e != null && e.actual > 0 ? e.actual.toStringAsFixed(0) : '');
    _paid = e?.paid ?? false;
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _item.dispose();
    _estimated.dispose();
    _actual.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final estimated = double.tryParse(_estimated.text) ?? 0;
      final actual = double.tryParse(_actual.text) ?? 0;
      if (widget.existing != null) {
        await ref.read(budgetProvider.notifier).updateItem(
              widget.existing!.copyWith(
                category: _category,
                item: _item.text.trim(),
                estimated: estimated,
                actual: actual,
                paid: _paid,
                notes: _notes.text.trim(),
              ),
            );
      } else {
        await ref.read(budgetProvider.notifier).addItem(
              category: _category,
              item: _item.text.trim(),
              estimated: estimated,
              actual: actual,
              paid: _paid,
              notes: _notes.text.trim(),
            );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
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
          isEditing ? 'Edit Item' : 'Add Budget Item',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ChipPicker(
              label: 'Category',
              options: AppConstants.budgetCategories,
              selected: _category,
              icons: _budgetCategoryIcons,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _item,
              decoration: const InputDecoration(labelText: 'Item name *'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _estimated,
                    decoration: const InputDecoration(labelText: 'Estimated (€)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _actual,
                    decoration: const InputDecoration(labelText: 'Actual (€)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Marked as paid', style: AppTextStyles.bodyMedium),
              subtitle: Text(
                'Toggle when you have paid this vendor/deposit.',
                style: AppTextStyles.bodySmall,
              ),
              value: _paid,
              onChanged: (v) => setState(() => _paid = v),
              activeThumbColor: AppColors.tealVibrant,
            ),
            const SizedBox(height: 16),
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
                  : Text(isEditing ? 'Save Changes' : 'Add to Budget'),
            ),
          ],
        ),
      ),
    );
  }
}
