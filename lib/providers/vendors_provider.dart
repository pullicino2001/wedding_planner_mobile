import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/vendor.dart';
import 'sheets_service_provider.dart';

const _uuid = Uuid();

class VendorsNotifier extends StateNotifier<AsyncValue<List<Vendor>>> {
  final Ref _ref;

  VendorsNotifier(this._ref) : super(const AsyncValue.loading()) {
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
      final vendors = await service.getVendors();
      if (mounted) state = AsyncValue.data(vendors);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> addVendor({
    required String name,
    required String category,
    String contactPerson = '',
    String email = '',
    String phone = '',
    double totalCost = 0,
    bool depositPaid = false,
    DateTime? depositDue,
    DateTime? balanceDue,
    String notes = '',
    List<Installment> installments = const [],
  }) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    final vendor = Vendor(
      id: _uuid.v4(),
      name: name,
      category: category,
      contactPerson: contactPerson,
      email: email,
      phone: phone,
      totalCost: totalCost,
      depositPaid: depositPaid,
      depositDue: depositDue,
      balanceDue: balanceDue,
      contractFileId: '',
      notes: notes,
      installments: installments,
      rowNumber: 0,
    );
    await service.addVendor(vendor);
    await _load();
  }

  Future<void> updateVendor(Vendor vendor) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    await service.updateVendor(vendor);
    await _load();
  }

  Future<void> deleteVendor(Vendor vendor) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    await service.deleteVendor(vendor.rowNumber);
    await _load();
  }
}

final vendorsProvider =
    StateNotifierProvider.autoDispose<VendorsNotifier, AsyncValue<List<Vendor>>>(
  (ref) => VendorsNotifier(ref),
);

final vendorStatsProvider = Provider.autoDispose<VendorStats>((ref) {
  final vendors = ref.watch(vendorsProvider).value ?? [];
  return VendorStats.from(vendors);
});
