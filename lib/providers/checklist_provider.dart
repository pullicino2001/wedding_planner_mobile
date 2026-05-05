import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/checklist_item.dart';
import 'sheets_service_provider.dart';

const _uuid = Uuid();

class ChecklistNotifier
    extends StateNotifier<AsyncValue<List<ChecklistItem>>> {
  final Ref _ref;

  ChecklistNotifier(this._ref) : super(const AsyncValue.loading()) {
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
      final items = await service.getChecklistItems();
      if (mounted) state = AsyncValue.data(items);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> addItem({
    required String item,
    required String destination,
    String personName = '',
    String notes = '',
  }) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    final ci = ChecklistItem(
      id: _uuid.v4(),
      item: item,
      destination: destination,
      personName: personName,
      inHand: false,
      packed: false,
      notes: notes,
      rowNumber: 0,
    );
    await service.addChecklistItem(ci);
    await _load();
  }

  Future<void> updateItem(ChecklistItem item) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    await service.updateChecklistItem(item);
    await _load();
  }

  Future<void> toggleInHand(ChecklistItem item) =>
      updateItem(item.copyWith(inHand: !item.inHand));

  Future<void> togglePacked(ChecklistItem item) =>
      updateItem(item.copyWith(packed: !item.packed));

  Future<void> deleteItem(ChecklistItem item) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    await service.deleteChecklistItem(item.rowNumber);
    await _load();
  }
}

final checklistProvider = StateNotifierProvider.autoDispose<ChecklistNotifier,
    AsyncValue<List<ChecklistItem>>>(
  (ref) => ChecklistNotifier(ref),
);
