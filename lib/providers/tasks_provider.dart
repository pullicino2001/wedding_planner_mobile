import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/task_item.dart';
import '../core/constants/app_constants.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import 'sheets_service_provider.dart';

const _uuid = Uuid();

class TasksNotifier extends StateNotifier<AsyncValue<List<TaskItem>>> {
  final Ref _ref;

  TasksNotifier(this._ref) : super(const AsyncValue.loading()) {
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
      final tasks = await service.getTasks();
      if (mounted) {
        state = AsyncValue.data(tasks);
        _syncSideEffects(tasks);
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  // Reschedule notifications + update widget after any data change.
  void _syncSideEffects(List<TaskItem> tasks) {
    NotificationService.rescheduleAll(tasks);
    WidgetService.update(tasks);
  }

  Future<void> refresh() => _load();

  Future<void> addTask({
    required String title,
    required String category,
    DateTime? dueDate,
    String priority = AppConstants.priorityMedium,
    String notes = '',
    String dueTime = '',
    String assignedTo = '',
  }) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    final task = TaskItem(
      id: _uuid.v4(),
      title: title,
      category: category,
      dueDate: dueDate,
      isDone: false,
      priority: priority,
      calendarEventId: '',
      notes: notes,
      dueTime: dueTime,
      assignedTo: assignedTo,
      rowNumber: 0,
    );
    await service.addTask(task);
    await _load();
  }

  Future<void> updateTask(TaskItem task) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    await service.updateTask(task);
    await _load();
  }

  Future<void> toggleDone(TaskItem task) async {
    await updateTask(task.copyWith(isDone: !task.isDone));
  }

  Future<void> deleteTask(TaskItem task) async {
    final service = await _ref.read(sheetsServiceProvider.future);
    if (service == null) return;
    await NotificationService.cancel(task.id);
    await service.deleteTask(task.rowNumber);
    await _load();
  }
}

final tasksProvider =
    StateNotifierProvider.autoDispose<TasksNotifier, AsyncValue<List<TaskItem>>>(
  (ref) => TasksNotifier(ref),
);

final taskStatsProvider = Provider.autoDispose<TaskStats>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? [];
  return TaskStats.from(tasks);
});
