import 'dart:convert';

// ── Helpers (shared by Vendor and Installment) ──────────────────────────────

DateTime? _parseDate(String s) {
  if (s.isEmpty) return null;
  try {
    return DateTime.parse(s);
  } catch (_) {
    return null;
  }
}

String _formatDate(DateTime? d) => d == null
    ? ''
    : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ── Installment ──────────────────────────────────────────────────────────────

class Installment {
  final String label;
  final double amount;
  final DateTime? dueDate;
  final bool paid;

  const Installment({
    required this.label,
    this.amount = 0,
    this.dueDate,
    this.paid = false,
  });

  bool get isOverdue =>
      !paid && dueDate != null && dueDate!.isBefore(DateTime.now());

  int? get daysUntil {
    if (dueDate == null) return null;
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    final d = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return d.difference(t).inDays;
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'due': _formatDate(dueDate),
        'paid': paid,
      };

  factory Installment.fromJson(Map<String, dynamic> json) => Installment(
        label: (json['label'] as String?) ?? '',
        amount: ((json['amount'] as num?) ?? 0).toDouble(),
        dueDate: _parseDate((json['due'] as String?) ?? ''),
        paid: (json['paid'] as bool?) ?? false,
      );

  Installment copyWith({
    String? label,
    double? amount,
    DateTime? dueDate,
    bool? paid,
    bool clearDate = false,
  }) =>
      Installment(
        label: label ?? this.label,
        amount: amount ?? this.amount,
        dueDate: clearDate ? null : (dueDate ?? this.dueDate),
        paid: paid ?? this.paid,
      );
}

// ── Vendor ───────────────────────────────────────────────────────────────────

class Vendor {
  final String id;
  final String name;
  final String category;
  final String contactPerson;
  final String email;
  final String phone;
  final double totalCost;
  // Legacy single-deposit fields (kept for sheet column compatibility)
  final bool depositPaid;
  final DateTime? depositDue;
  final DateTime? balanceDue;
  final String contractFileId;
  final String notes;
  // Installments list stored as JSON in column M
  final List<Installment> installments;
  final int rowNumber;

  const Vendor({
    required this.id,
    required this.name,
    required this.category,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.totalCost,
    required this.depositPaid,
    required this.depositDue,
    required this.balanceDue,
    required this.contractFileId,
    required this.notes,
    required this.rowNumber,
    this.installments = const [],
  });

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get hasInstallments => installments.isNotEmpty;

  bool get isOverdue {
    if (hasInstallments) {
      return installments.any((i) => i.isOverdue);
    }
    final now = DateTime.now();
    if (depositDue != null && !depositPaid && depositDue!.isBefore(now)) return true;
    if (balanceDue != null && balanceDue!.isBefore(now)) return true;
    return false;
  }

  bool get hasUpcomingDeadline {
    if (hasInstallments) {
      return installments.any((i) =>
          !i.paid && i.dueDate != null && i.dueDate!.isAfter(DateTime.now()));
    }
    final now = DateTime.now();
    if (depositDue != null && !depositPaid && depositDue!.isAfter(now)) return true;
    if (balanceDue != null && balanceDue!.isAfter(now)) return true;
    return false;
  }

  int? get daysUntilNextDeadline {
    if (hasInstallments) {
      final upcoming = installments
          .where((i) => !i.paid && i.dueDate != null)
          .map((i) => i.daysUntil!)
          .toList();
      if (upcoming.isEmpty) return null;
      upcoming.sort();
      return upcoming.first;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? next;
    if (depositDue != null && !depositPaid) next = depositDue;
    if (balanceDue != null && (next == null || balanceDue!.isBefore(next))) {
      next = balanceDue;
    }
    if (next == null) return null;
    return DateTime(next.year, next.month, next.day).difference(today).inDays;
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  factory Vendor.fromSheetRow(List<String> row, int rowNumber) {
    List<Installment> installments = [];
    final rawJson = _cell(row, 12);
    if (rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        installments = decoded
            .map((e) => Installment.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return Vendor(
      id: _cell(row, 0),
      name: _cell(row, 1),
      category: _cell(row, 2),
      contactPerson: _cell(row, 3),
      email: _cell(row, 4),
      phone: _cell(row, 5),
      totalCost: double.tryParse(_cell(row, 6)) ?? 0,
      depositPaid: _cell(row, 7).toLowerCase() == 'true' ||
          _cell(row, 7).toLowerCase() == 'yes',
      depositDue: _parseDate(_cell(row, 8)),
      balanceDue: _parseDate(_cell(row, 9)),
      contractFileId: _cell(row, 10),
      notes: _cell(row, 11),
      installments: installments,
      rowNumber: rowNumber,
    );
  }

  List<Object> toSheetRow() {
    // Derive legacy fields from installments so the sheet stays readable
    final lastUnpaid = installments.isEmpty
        ? null
        : installments.lastWhere((i) => !i.paid,
            orElse: () => installments.last);
    final effectiveDepositPaid = hasInstallments
        ? installments.first.paid
        : depositPaid;
    final effectiveDepositDue = hasInstallments
        ? (installments.isNotEmpty ? installments.first.dueDate : depositDue)
        : depositDue;
    final effectiveBalanceDue = hasInstallments
        ? (installments.length > 1 ? lastUnpaid?.dueDate : balanceDue)
        : balanceDue;

    return [
      id,
      name,
      category,
      contactPerson,
      email,
      phone,
      totalCost,
      effectiveDepositPaid ? 'Yes' : 'No',
      _formatDate(effectiveDepositDue),
      _formatDate(effectiveBalanceDue),
      contractFileId,
      notes,
      installments.isEmpty ? '' : jsonEncode(installments.map((i) => i.toJson()).toList()),
    ];
  }

  Vendor copyWith({
    String? name,
    String? category,
    String? contactPerson,
    String? email,
    String? phone,
    double? totalCost,
    bool? depositPaid,
    DateTime? depositDue,
    DateTime? balanceDue,
    String? contractFileId,
    String? notes,
    List<Installment>? installments,
    bool clearDepositDue = false,
    bool clearBalanceDue = false,
  }) {
    return Vendor(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      contactPerson: contactPerson ?? this.contactPerson,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      totalCost: totalCost ?? this.totalCost,
      depositPaid: depositPaid ?? this.depositPaid,
      depositDue: clearDepositDue ? null : (depositDue ?? this.depositDue),
      balanceDue: clearBalanceDue ? null : (balanceDue ?? this.balanceDue),
      contractFileId: contractFileId ?? this.contractFileId,
      notes: notes ?? this.notes,
      installments: installments ?? this.installments,
      rowNumber: rowNumber,
    );
  }

  static String _cell(List<String> row, int index) =>
      index < row.length ? row[index].trim() : '';
}

// ── VendorStats ───────────────────────────────────────────────────────────────

class VendorStats {
  final int total;
  final int booked;
  final int overdueCount;

  const VendorStats({
    required this.total,
    required this.booked,
    required this.overdueCount,
  });

  double get bookedProgress =>
      total == 0 ? 0 : (booked / total).clamp(0.0, 1.0);

  factory VendorStats.from(List<Vendor> vendors) {
    return VendorStats(
      total: vendors.length,
      booked: vendors.where((v) => v.totalCost > 0).length,
      overdueCount: vendors.where((v) => v.isOverdue).length,
    );
  }
}
