import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/guest.dart';
import '../../providers/guests_provider.dart';

const _dietaryIcons = <String, IconData>{
  'Standard':      Icons.restaurant_outlined,
  'Vegetarian':    Icons.eco_outlined,
  'Vegan':         Icons.spa_outlined,
  'Gluten Free':   Icons.no_food_outlined,
  "Children's":    Icons.child_care_outlined,
  'Not Attending': Icons.block_outlined,
};

class GuestFormScreen extends ConsumerStatefulWidget {
  final Guest? existing;

  const GuestFormScreen({super.key, this.existing});

  @override
  ConsumerState<GuestFormScreen> createState() => _GuestFormScreenState();
}

class _GuestFormScreenState extends ConsumerState<GuestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _dietary;
  late String _rsvp;
  late String _meal;
  late bool _plusOne;
  String _plusOneName = '';
  late String _relation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _firstName = TextEditingController(text: e?.firstName ?? '');
    _lastName = TextEditingController(text: e?.lastName ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _dietary = TextEditingController(text: e?.dietary ?? '');
    _rsvp = e?.rsvpStatus ?? AppConstants.rsvpPending;
    final rawMeal = e?.mealChoice ?? '';
    _meal = AppConstants.mealChoices.contains(rawMeal)
        ? rawMeal
        : AppConstants.mealChoices.first;
    _plusOne = e?.hasPlusOne ?? false;
    _relation = e?.relation ?? '';
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _dietary.dispose();
    super.dispose();
  }

  Future<void> _handlePlusOneToggle(bool value) async {
    if (!value) {
      setState(() {
        _plusOne = false;
        _plusOneName = '';
      });
      return;
    }

    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Plus one's name"),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'First and last name (optional)'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null) {
      setState(() {
        _plusOne = true;
        _plusOneName = name;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final notifier = ref.read(guestsProvider.notifier);

      if (widget.existing != null) {
        await notifier.updateGuest(
          widget.existing!.copyWith(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            rsvpStatus: _rsvp,
            mealChoice: _meal,
            dietary: _dietary.text.trim(),
            hasPlusOne: _plusOne,
            relation: _relation,
          ),
        );
      } else {
        await notifier.addGuest(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          rsvpStatus: _rsvp,
          mealChoice: _meal,
          dietary: _dietary.text.trim(),
          hasPlusOne: _plusOne,
          relation: _relation,
        );

        // Add plus one as a separate guest entry
        if (_plusOne) {
          final mainFirst = _firstName.text.trim();
          final mainLast = _lastName.text.trim();
          String poFirst, poLast;
          if (_plusOneName.isNotEmpty) {
            final parts = _plusOneName.split(' ');
            poFirst = parts.first;
            poLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          } else {
            poFirst = '$mainFirst $mainLast'.trim();
            poLast = '+1';
          }
          await notifier.addGuest(
            firstName: poFirst,
            lastName: poLast,
            rsvpStatus: _rsvp,
            relation: _relation,
          );
        }
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

  Future<void> _addCustomRelation() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add custom category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Cousins, College Friends…'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final current = ref.read(customRelationsProvider);
      if (!current.contains(result)) {
        ref.read(customRelationsProvider.notifier).state = [...current, result];
      }
      setState(() => _relation = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final customRelations = ref.watch(customRelationsProvider);
    final allRelations = [...AppConstants.guestRelations, ...customRelations];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Guest' : 'Add Guest',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Name
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstName,
                    decoration: const InputDecoration(labelText: 'First name *'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastName,
                    decoration: const InputDecoration(labelText: 'Last name'),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Relation chips
            Text('Relation', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...allRelations.map((rel) {
                  final isSelected = _relation == rel;
                  return ChoiceChip(
                    label: Text(rel),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _relation = isSelected ? '' : rel),
                    selectedColor: AppColors.tealVibrant,
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.tealVibrant : AppColors.divider,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    showCheckmark: false,
                  );
                }),
                ActionChip(
                  label: const Text('+ Custom'),
                  avatar: const Icon(Icons.add, size: 16),
                  onPressed: _addCustomRelation,
                  backgroundColor: AppColors.surfaceVariant,
                  labelStyle: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.dustyRose,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(color: AppColors.dustyRose.withAlpha(120)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // RSVP
            Text('RSVP Status', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'pending',
                  label: Text('Pending'),
                  icon: Icon(Icons.schedule_outlined, size: 16),
                ),
                ButtonSegment(
                  value: 'confirmed',
                  label: Text('Confirmed'),
                  icon: Icon(Icons.check_circle_outline, size: 16),
                ),
                ButtonSegment(
                  value: 'declined',
                  label: Text('Declined'),
                  icon: Icon(Icons.cancel_outlined, size: 16),
                ),
              ],
              selected: {_rsvp},
              onSelectionChanged: (s) => setState(() => _rsvp = s.first),
              style: ButtonStyle(
                iconColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return AppColors.textSecondary;
                }),
              ),
            ),
            const SizedBox(height: 24),

            // Dietary Restrictions dropdown
            Text('Dietary Restrictions', style: AppTextStyles.labelLarge),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _meal,
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: AppConstants.mealChoices.map((choice) {
                final icon = _dietaryIcons[choice];
                return DropdownMenuItem(
                  value: choice,
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: AppColors.tealVibrant),
                        const SizedBox(width: 10),
                      ],
                      Text(choice, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _meal = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dietary,
              decoration: const InputDecoration(
                  labelText: 'Additional dietary notes / allergies'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Plus one
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Plus one', style: AppTextStyles.bodyMedium),
              subtitle: _plusOne && _plusOneName.isNotEmpty
                  ? Text(_plusOneName, style: AppTextStyles.bodySmall)
                  : _plusOne
                      ? Text('Name not set', style: AppTextStyles.bodySmall)
                      : null,
              value: _plusOne,
              onChanged: _handlePlusOneToggle,
              activeThumbColor: AppColors.tealVibrant,
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
                  : Text(isEditing ? 'Save Changes' : 'Add Guest'),
            ),
          ],
        ),
      ),
    );
  }
}
