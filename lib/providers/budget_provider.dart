import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/budget_item.dart';
import '../models/vendor.dart';
import 'sheets_service_provider.dart';
import 'vendors_provider.dart';

const _uuid = Uuid();

class BudgetNotifier extends StateNotifier<AsyncValue<List<BudgetItem>>> {
  final Ref _ref;

  BudgetNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final service = await _ref.read(sheetsServiceProvider.future);
      if (!mounted) return;
      if (service == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final items = await service.getBudgetItems();
      if (mounted) state = AsyncValue.data(items);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> addItem({
    required String category,
    required String item,
    required double estimated,
    required double actual,
    required bool paid,
    required String notes,
  }) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    final newItem = BudgetItem(
      id: _uuid.v4(),
      category: category,
      item: item,
      estimated: estimated,
      actual: actual,
      paid: paid,
      notes: notes,
      rowNumber: 0,
    );
    await service.addBudgetItem(newItem);
    await _load();
  }

  Future<void> updateItem(BudgetItem item) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    await service.updateBudgetItem(item);
    await _load();
  }

  Future<void> deleteItem(BudgetItem item) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    await service.deleteBudgetItem(item.rowNumber);
    await _load();
  }
}

final budgetProvider =
    StateNotifierProvider.autoDispose<BudgetNotifier, AsyncValue<List<BudgetItem>>>(
  (ref) => BudgetNotifier(ref),
);

final budgetStatsProvider = Provider.autoDispose<BudgetStats>((ref) {
  final items = ref.watch(budgetProvider).value ?? [];
  return BudgetStats.from(items);
});

// ── Combined view (budget items + vendor costs) ────────────────────────────

class CombinedBudgetStats {
  final double manualEstimated;
  final double manualActual;
  final double vendorTotal;
  final double vendorPaid;

  const CombinedBudgetStats({
    required this.manualEstimated,
    required this.manualActual,
    required this.vendorTotal,
    required this.vendorPaid,
  });

  double get totalEstimated => manualEstimated + vendorTotal;
  double get totalActual => manualActual + vendorPaid;
  double get remaining =>
      (totalEstimated - totalActual).clamp(0, double.infinity);
  double get spentProgress =>
      totalEstimated == 0 ? 0 : (totalActual / totalEstimated).clamp(0.0, 1.0);
}

/// Returns how much a vendor has been paid so far (from installments).
double vendorPaidAmount(Vendor v) {
  if (v.hasInstallments) {
    return v.installments
        .where((i) => i.paid)
        .fold(0.0, (s, i) => s + i.amount);
  }
  // Legacy: deposit paid but no installment amounts — treat totalCost as paid
  // only when both deposit and balance show paid (best approximation).
  return 0.0;
}

final combinedBudgetStatsProvider =
    Provider.autoDispose<CombinedBudgetStats>((ref) {
  final budgetItems = ref.watch(budgetProvider).value ?? [];
  final vendors = ref.watch(vendorsProvider).value ?? [];

  return CombinedBudgetStats(
    manualEstimated: budgetItems.fold(0.0, (s, i) => s + i.estimated),
    manualActual: budgetItems.fold(0.0, (s, i) => s + i.actual),
    vendorTotal: vendors.fold(0.0, (s, v) => s + v.totalCost),
    vendorPaid: vendors.fold(0.0, (s, v) => s + vendorPaidAmount(v)),
  );
});
