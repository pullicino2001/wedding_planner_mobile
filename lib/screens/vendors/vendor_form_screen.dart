import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/vendor.dart';
import '../../providers/vendors_provider.dart';
import '../../widgets/common/chip_picker.dart';

// Icon for each vendor category
const _categoryIcons = <String, IconData>{
  'Venue':            Icons.location_city_outlined,
  'Caterer':          Icons.restaurant_outlined,
  'Photographer':     Icons.camera_alt_outlined,
  'Videographer':     Icons.videocam_outlined,
  'Florist':          Icons.local_florist_outlined,
  'Band / DJ':        Icons.music_note_outlined,
  'Baker':            Icons.cake_outlined,
  'Hair & Makeup':    Icons.face_retouching_natural_outlined,
  'Celebrant':        Icons.favorite_border,
  'Transport':        Icons.directions_car_outlined,
  'Stationery':       Icons.mail_outline,
  'Accommodation':    Icons.hotel_outlined,
  'Other':            Icons.more_horiz,
};

final _dateFormat = DateFormat('d MMM y');

// ── Mutable installment holder for form state ─────────────────────────────────

class _InstallmentEntry {
  final TextEditingController label;
  final TextEditingController amount;
  DateTime? dueDate;
  bool paid;

  _InstallmentEntry({
    String labelText = '',
    String amountText = '',
    this.dueDate,
    this.paid = false,
  })  : label = TextEditingController(text: labelText),
        amount = TextEditingController(text: amountText);

  void dispose() {
    label.dispose();
    amount.dispose();
  }

  Installment toInstallment() => Installment(
        label: label.text.trim(),
        amount: double.tryParse(amount.text) ?? 0,
        dueDate: dueDate,
        paid: paid,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class VendorFormScreen extends ConsumerStatefulWidget {
  final Vendor? existing;

  const VendorFormScreen({super.key, this.existing});

  @override
  ConsumerState<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends ConsumerState<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _category;
  late TextEditingController _name;
  late TextEditingController _contact;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _totalCost;
  late TextEditingController _notes;
  late List<_InstallmentEntry> _installments;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _category = e?.category ?? AppConstants.vendorCategories.first;
    _name = TextEditingController(text: e?.name ?? '');
    _contact = TextEditingController(text: e?.contactPerson ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _totalCost = TextEditingController(
        text: e != null && e.totalCost > 0
            ? e.totalCost.toStringAsFixed(0)
            : '');
    _notes = TextEditingController(text: e?.notes ?? '');

    // Initialise installments
    if (e != null && e.installments.isNotEmpty) {
      _installments = e.installments
          .map((i) => _InstallmentEntry(
                labelText: i.label,
                amountText: i.amount > 0 ? i.amount.toStringAsFixed(0) : '',
                dueDate: i.dueDate,
                paid: i.paid,
              ))
          .toList();
    } else if (e != null && (e.depositDue != null || e.balanceDue != null)) {
      // Migrate old deposit/balance fields to installments
      _installments = [
        _InstallmentEntry(
          labelText: 'Deposit',
          dueDate: e.depositDue,
          paid: e.depositPaid,
        ),
        if (e.balanceDue != null)
          _InstallmentEntry(
            labelText: 'Balance',
            dueDate: e.balanceDue,
            paid: false,
          ),
      ];
    } else {
      // Fresh vendor — start with two default entries
      _installments = [
        _InstallmentEntry(labelText: 'Deposit'),
        _InstallmentEntry(labelText: 'Balance'),
      ];
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _email.dispose();
    _phone.dispose();
    _totalCost.dispose();
    _notes.dispose();
    for (final entry in _installments) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addInstallment() {
    setState(() {
      _installments.add(_InstallmentEntry(
        labelText: 'Instalment ${_installments.length + 1}',
      ));
    });
  }

  void _removeInstallment(int index) {
    setState(() {
      _installments[index].dispose();
      _installments.removeAt(index);
    });
  }

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
        context: context,
        initialDate: initial ?? DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final cost = double.tryParse(_totalCost.text) ?? 0;
      final installments = _installments.map((e) => e.toInstallment()).toList();

      if (widget.existing != null) {
        await ref.read(vendorsProvider.notifier).updateVendor(
              widget.existing!.copyWith(
                name: _name.text.trim(),
                category: _category,
                contactPerson: _contact.text.trim(),
                email: _email.text.trim(),
                phone: _phone.text.trim(),
                totalCost: cost,
                notes: _notes.text.trim(),
                installments: installments,
              ),
            );
      } else {
        await ref.read(vendorsProvider.notifier).addVendor(
              name: _name.text.trim(),
              category: _category,
              contactPerson: _contact.text.trim(),
              email: _email.text.trim(),
              phone: _phone.text.trim(),
              totalCost: cost,
              depositPaid: installments.isNotEmpty && installments.first.paid,
              depositDue:
                  installments.isNotEmpty ? installments.first.dueDate : null,
              balanceDue: installments.length > 1
                  ? installments.last.dueDate
                  : null,
              notes: _notes.text.trim(),
              installments: installments,
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
          isEditing ? 'Edit Vendor' : 'Add Vendor',
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
              options: AppConstants.vendorCategories,
              selected: _category,
              icons: _categoryIcons,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration:
                  const InputDecoration(labelText: 'Business / Vendor name *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Contact
            Text('Contact Details', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contact,
              decoration: const InputDecoration(labelText: 'Contact person'),
              textCapitalization: TextCapitalization.words,
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

            // Total cost
            Text('Financials', style: AppTextStyles.labelLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalCost,
              decoration:
                  const InputDecoration(labelText: 'Total contract cost (€)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),

            // Installments
            Row(
              children: [
                Text('Payment Instalments', style: AppTextStyles.labelLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addInstallment,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._installments.asMap().entries.map((entry) {
              final i = entry.key;
              final inst = entry.value;
              return _InstallmentCard(
                entry: inst,
                index: i,
                total: _installments.length,
                onRemove: _installments.length > 1
                    ? () => _removeInstallment(i)
                    : null,
                onPickDate: () async {
                  final d = await _pickDate(inst.dueDate);
                  if (d != null) setState(() => inst.dueDate = d);
                },
                onClearDate: () => setState(() => inst.dueDate = null),
                onTogglePaid: (v) => setState(() => inst.paid = v),
              );
            }),

            const SizedBox(height: 24),
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
                  : Text(isEditing ? 'Save Changes' : 'Add Vendor'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Installment card widget ───────────────────────────────────────────────────

class _InstallmentCard extends StatelessWidget {
  final _InstallmentEntry entry;
  final int index;
  final int total;
  final VoidCallback? onRemove;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;
  final ValueChanged<bool> onTogglePaid;

  const _InstallmentCard({
    required this.entry,
    required this.index,
    required this.total,
    required this.onRemove,
    required this.onPickDate,
    required this.onClearDate,
    required this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: entry.paid
                        ? AppColors.success.withAlpha(30)
                        : AppColors.tealVibrant.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: entry.paid
                            ? AppColors.success
                            : AppColors.tealVibrant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: entry.label,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: AppTextStyles.bodyMedium,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: AppColors.danger,
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          const Divider(height: 16, indent: 16, endIndent: 16),

          // Amount + date row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                // Amount
                Expanded(
                  child: TextFormField(
                    controller: entry.amount,
                    decoration: const InputDecoration(
                      labelText: 'Amount (€)',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                // Date picker
                Expanded(
                  child: GestureDetector(
                    onTap: onPickDate,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.dueDate != null
                                ? _dateFormat.format(entry.dueDate!)
                                : 'Set due date',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: entry.dueDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (entry.dueDate != null)
                          GestureDetector(
                            onTap: onClearDate,
                            child: const Icon(Icons.clear,
                                size: 14, color: AppColors.warmGrey),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Paid toggle
          SwitchListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            dense: true,
            title: Text(
              entry.paid ? 'Paid' : 'Not yet paid',
              style: AppTextStyles.bodySmall.copyWith(
                color: entry.paid ? AppColors.success : AppColors.textSecondary,
              ),
            ),
            value: entry.paid,
            onChanged: onTogglePaid,
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}
