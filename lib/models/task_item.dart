import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class TaskItem {
  final String id;
  final String title;
  final String category;
  final DateTime? dueDate;
  final bool isDone;
  final String priority; // 'low', 'medium', 'high'
  final String calendarEventId;
  final String notes;
  final String dueTime;    // 'HH:MM' 24h, empty = no time
  final String assignedTo; // 'Bride', 'Groom', 'Both', ''
  final int rowNumber;

  const TaskItem({
    required this.id,
    required this.title,
    required this.category,
    required this.dueDate,
    required this.isDone,
    required this.priority,
    required this.calendarEventId,
    required this.notes,
    required this.dueTime,
    required this.assignedTo,
    required this.rowNumber,
  });

  bool get isOverdue {
    if (isDone || dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.difference(today).inDays;
  }

  TimeOfDay? get timeOfDay {
    if (dueTime.isEmpty) return null;
    final parts = dueTime.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  factory TaskItem.fromSheetRow(List<String> row, int rowNumber) {
    return TaskItem(
      id: _cell(row, 0),
      title: _cell(row, 1),
      category: _cell(row, 2),
      dueDate: _parseDate(_cell(row, 3)),
      isDone: _cell(row, 4).toLowerCase() == 'true' || _cell(row, 4).toLowerCase() == 'yes',
      priority: _cell(row, 5).isEmpty ? AppConstants.priorityMedium : _cell(row, 5),
      calendarEventId: _cell(row, 6),
      notes: _cell(row, 7),
      dueTime: _cell(row, 8),
      assignedTo: _cell(row, 9),
      rowNumber: rowNumber,
    );
  }

  List<Object> toSheetRow() => [
        id,
        title,
        category,
        _formatDate(dueDate),
        isDone ? 'Yes' : 'No',
        priority,
        calendarEventId,
        notes,
        dueTime,
        assignedTo,
      ];

  TaskItem copyWith({
    String? title,
    String? category,
    DateTime? dueDate,
    bool? isDone,
    String? priority,
    String? calendarEventId,
    String? notes,
    String? dueTime,
    String? assignedTo,
    bool clearDueDate = false,
    bool clearDueTime = false,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isDone: isDone ?? this.isDone,
      priority: priority ?? this.priority,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      notes: notes ?? this.notes,
      dueTime: clearDueTime ? '' : (dueTime ?? this.dueTime),
      assignedTo: assignedTo ?? this.assignedTo,
      rowNumber: rowNumber,
    );
  }

  static String _cell(List<String> row, int index) =>
      index < row.length ? row[index].trim() : '';

  static DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(DateTime? d) =>
      d == null
          ? ''
          : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class TaskStats {
  final int total;
  final int done;
  final int overdue;

  const TaskStats({
    required this.total,
    required this.done,
    required this.overdue,
  });

  double get doneProgress =>
      total == 0 ? 0 : (done / total).clamp(0.0, 1.0);

  factory TaskStats.from(List<TaskItem> tasks) {
    return TaskStats(
      total: tasks.length,
      done: tasks.where((t) => t.isDone).length,
      overdue: tasks.where((t) => t.isOverdue).length,
    );
  }
}
