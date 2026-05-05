import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/running_order_item.dart';
import 'sheets_service_provider.dart';

const _uuid = Uuid();

class RunningOrderNotifier
    extends StateNotifier<AsyncValue<List<RunningOrderItem>>> {
  final Ref _ref;

  RunningOrderNotifier(this._ref) : super(const AsyncValue.loading()) {
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
      final items = await service.getRunningOrderItems();
      if (mounted) state = AsyncValue.data(items);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> addItem({
    required String time,
    required String phase,
    required String description,
    String notes = '',
  }) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    final item = RunningOrderItem(
      id: _uuid.v4(),
      time: time,
      phase: phase,
      description: description,
      notes: notes,
      rowNumber: 0,
    );
    await service.addRunningOrderItem(item);
    await _load();
  }

  Future<void> updateItem(RunningOrderItem item) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    await service.updateRunningOrderItem(item);
    await _load();
  }

  Future<void> deleteItem(RunningOrderItem item) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    await service.deleteRunningOrderItem(item.rowNumber);
    await _load();
  }
}

final runningOrderProvider = StateNotifierProvider.autoDispose<
    RunningOrderNotifier, AsyncValue<List<RunningOrderItem>>>(
  (ref) => RunningOrderNotifier(ref),
);
